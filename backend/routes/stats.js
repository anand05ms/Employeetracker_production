// backend/routes/stats.js
// NEW FILE: Statistics and analytics endpoints

const express = require("express");
const router = express.Router();
const { protect } = require("../middleware/auth");

const Attendance = require("../models/Attendance");

// Helper: Calculate distance between two coordinates (Haversine formula)
function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371e3; // Earth radius in meters
  const φ1 = (lat1 * Math.PI) / 180;
  const φ2 = (lat2 * Math.PI) / 180;
  const Δφ = ((lat2 - lat1) * Math.PI) / 180;
  const Δλ = ((lon2 - lon1) * Math.PI) / 180;

  const a =
    Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
    Math.cos(φ1) * Math.cos(φ2) * Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return R * c; // Distance in meters
}

// GET /api/stats/my-stats?period=today|week|month
// Get employee's statistics for specified period
router.get("/my-stats", protect, async (req, res) => {
  try {
    const { period = "today" } = req.query;
    const employeeId = req.user.id;

    // Calculate date range
    let startDate, endDate;
    const now = new Date();

    switch (period) {
      case "today":
        startDate = new Date(
          now.getFullYear(),
          now.getMonth(),
          now.getDate(),
          0,
          0,
          0,
        );
        endDate = new Date(
          now.getFullYear(),
          now.getMonth(),
          now.getDate(),
          23,
          59,
          59,
        );
        break;
      case "week":
        const weekStart = new Date(now);
        weekStart.setDate(now.getDate() - now.getDay()); // Sunday
        startDate = new Date(
          weekStart.getFullYear(),
          weekStart.getMonth(),
          weekStart.getDate(),
          0,
          0,
          0,
        );
        endDate = new Date(
          now.getFullYear(),
          now.getMonth(),
          now.getDate(),
          23,
          59,
          59,
        );
        break;
      case "month":
        startDate = new Date(now.getFullYear(), now.getMonth(), 1, 0, 0, 0);
        endDate = new Date(
          now.getFullYear(),
          now.getMonth(),
          now.getDate(),
          23,
          59,
          59,
        );
        break;
      default:
        startDate = new Date(
          now.getFullYear(),
          now.getMonth(),
          now.getDate(),
          0,
          0,
          0,
        );
        endDate = new Date(
          now.getFullYear(),
          now.getMonth(),
          now.getDate(),
          23,
          59,
          59,
        );
    }

    console.log(
      `📊 Fetching stats for ${employeeId} from ${startDate} to ${endDate}`,
    );

    // Find all attendances in period
    const attendances = await Attendance.find({
      employee: employeeId,
      checkInTime: { $gte: startDate, $lte: endDate },
    });

    console.log(`Found ${attendances.length} attendance records`);

    // Initialize statistics
    let totalDistance = 0;
    let totalDuration = 0;
    let speedSum = 0;
    let maxSpeed = 0;
    let speedCount = 0;
    let totalVisits = 0;

    // Process each attendance
    for (const attendance of attendances) {
      // Calculate distance from route
      if (attendance.route && attendance.route.length > 1) {
        for (let i = 1; i < attendance.route.length; i++) {
          const prev = attendance.route[i - 1];
          const curr = attendance.route[i];

          // Extract coordinates
          const lat1 = prev.coordinates?.[1] || prev.latitude;
          const lng1 = prev.coordinates?.[0] || prev.longitude;
          const lat2 = curr.coordinates?.[1] || curr.latitude;
          const lng2 = curr.coordinates?.[0] || curr.longitude;

          if (lat1 && lng1 && lat2 && lng2) {
            const distance = calculateDistance(lat1, lng1, lat2, lng2);
            totalDistance += distance;
          }

          // Track speed
          const speed = curr.speed || 0;
          if (speed > 0) {
            speedSum += speed;
            speedCount++;
            if (speed > maxSpeed) {
              maxSpeed = speed;
            }
          }
        }
      }

      // Calculate duration
      if (attendance.checkOutTime) {
        const durationMs = attendance.checkOutTime - attendance.checkInTime;
        const durationMin = durationMs / (1000 * 60);
        totalDuration += durationMin;
      } else if (attendance.checkInTime) {
        // If still checked in, calculate duration until now
        const durationMs = Date.now() - attendance.checkInTime;
        const durationMin = durationMs / (1000 * 60);
        totalDuration += durationMin;
      }

      // Count visits (if you have visits in attendance model)
      if (attendance.visits && Array.isArray(attendance.visits)) {
        totalVisits += attendance.visits.length;
      }
    }

    const stats = {
      distance: totalDistance / 1000, // Convert to km
      duration: Math.round(totalDuration), // in minutes
      avgSpeed: speedCount > 0 ? speedSum / speedCount : 0,
      maxSpeed: maxSpeed,
      visits: totalVisits,
      days: attendances.length,
    };

    console.log(`📊 Stats calculated:`, stats);

    res.json({
      success: true,
      ...stats,
    });
  } catch (error) {
    console.error("❌ Stats error:", error);
    res.status(500).json({
      success: false,
      message: error.message,
      distance: 0,
      duration: 0,
      avgSpeed: 0,
      maxSpeed: 0,
      visits: 0,
      days: 0,
    });
  }
});

// GET /api/stats/today-timeline
// Get today's journey timeline
router.get("/today-timeline", protect, async (req, res) => {
  try {
    const employeeId = req.user.id;

    // Get today's date range
    const now = new Date();
    const startDate = new Date(
      now.getFullYear(),
      now.getMonth(),
      now.getDate(),
      0,
      0,
      0,
    );
    const endDate = new Date(
      now.getFullYear(),
      now.getMonth(),
      now.getDate(),
      23,
      59,
      59,
    );

    // Find today's attendance
    const attendance = await Attendance.findOne({
      employee: employeeId,
      checkInTime: { $gte: startDate, $lte: endDate },
    });

    if (!attendance) {
      return res.json({
        success: true,
        timeline: [],
      });
    }

    const timeline = [];

    // Check in event
    if (attendance.checkInTime) {
      const time = new Date(attendance.checkInTime);
      timeline.push({
        time: time.toLocaleTimeString("en-US", {
          hour: "2-digit",
          minute: "2-digit",
        }),
        title: "Checked In",
        subtitle: attendance.checkInLocation?.address || "Office",
        type: "check_in",
        data: {
          location: attendance.checkInLocation?.address,
        },
      });
    }

    // Process route for significant events
    if (attendance.route && attendance.route.length > 0) {
      let lastSignificantSpeed = 0;
      let lastEventTime = attendance.checkInTime;

      for (let i = 0; i < attendance.route.length; i++) {
        const point = attendance.route[i];
        const speed = point.speed || 0;
        const timestamp = point.timestamp || point.createdAt;

        if (!timestamp) continue;

        const time = new Date(timestamp);
        const timeSinceLastEvent =
          (time - new Date(lastEventTime)) / (1000 * 60); // minutes

        // Detect movement start (speed > 5 km/h after being stationary)
        if (lastSignificantSpeed < 5 && speed > 5 && timeSinceLastEvent > 5) {
          timeline.push({
            time: time.toLocaleTimeString("en-US", {
              hour: "2-digit",
              minute: "2-digit",
            }),
            title: "Started Moving",
            subtitle: point.address || `Speed: ${speed.toFixed(0)} km/h`,
            type: "moving",
            data: {
              speed: `${speed.toFixed(0)} km/h`,
            },
          });
          lastEventTime = timestamp;
        }

        // Detect stop (speed < 5 km/h after moving)
        if (lastSignificantSpeed > 5 && speed < 5 && timeSinceLastEvent > 3) {
          timeline.push({
            time: time.toLocaleTimeString("en-US", {
              hour: "2-digit",
              minute: "2-digit",
            }),
            title: "Stopped",
            subtitle: point.address || "Location",
            type: "visit",
            data: {
              duration: `${timeSinceLastEvent.toFixed(0)} min`,
            },
          });
          lastEventTime = timestamp;
        }

        lastSignificantSpeed = speed;
      }
    }

    // Check out event
    if (attendance.checkOutTime) {
      const time = new Date(attendance.checkOutTime);
      timeline.push({
        time: time.toLocaleTimeString("en-US", {
          hour: "2-digit",
          minute: "2-digit",
        }),
        title: "Checked Out",
        subtitle: attendance.checkOutLocation?.address || "Office",
        type: "check_out",
        data: {
          location: attendance.checkOutLocation?.address,
        },
      });
    }

    console.log(`📅 Timeline generated: ${timeline.length} events`);

    res.json({
      success: true,
      timeline: timeline,
    });
  } catch (error) {
    console.error("❌ Timeline error:", error);
    res.status(500).json({
      success: false,
      message: error.message,
      timeline: [],
    });
  }
});

// GET /api/stats/employee-stats/:employeeId (Admin only)
// Get specific employee's statistics
router.get("/employee-stats/:employeeId", protect, async (req, res) => {
  try {
    // Check if admin (add your admin check logic)
    if (req.user.role !== "admin") {
      return res.status(403).json({
        success: false,
        message: "Unauthorized",
      });
    }

    const { employeeId } = req.params;
    const { period = "today" } = req.query;

    // Calculate date range (same as my-stats)
    let startDate, endDate;
    const now = new Date();

    switch (period) {
      case "today":
        startDate = new Date(
          now.getFullYear(),
          now.getMonth(),
          now.getDate(),
          0,
          0,
          0,
        );
        endDate = new Date(
          now.getFullYear(),
          now.getMonth(),
          now.getDate(),
          23,
          59,
          59,
        );
        break;
      case "week":
        const weekStart = new Date(now);
        weekStart.setDate(now.getDate() - now.getDay());
        startDate = new Date(
          weekStart.getFullYear(),
          weekStart.getMonth(),
          weekStart.getDate(),
          0,
          0,
          0,
        );
        endDate = new Date(
          now.getFullYear(),
          now.getMonth(),
          now.getDate(),
          23,
          59,
          59,
        );
        break;
      case "month":
        startDate = new Date(now.getFullYear(), now.getMonth(), 1, 0, 0, 0);
        endDate = new Date(
          now.getFullYear(),
          now.getMonth(),
          now.getDate(),
          23,
          59,
          59,
        );
        break;
    }

    const attendances = await Attendance.find({
      employee: employeeId,
      checkInTime: { $gte: startDate, $lte: endDate },
    });

    // Calculate stats (same logic as my-stats)
    let totalDistance = 0;
    let totalDuration = 0;
    let speedSum = 0;
    let maxSpeed = 0;
    let speedCount = 0;

    for (const attendance of attendances) {
      if (attendance.route && attendance.route.length > 1) {
        for (let i = 1; i < attendance.route.length; i++) {
          const prev = attendance.route[i - 1];
          const curr = attendance.route[i];

          const lat1 = prev.coordinates?.[1] || prev.latitude;
          const lng1 = prev.coordinates?.[0] || prev.longitude;
          const lat2 = curr.coordinates?.[1] || curr.latitude;
          const lng2 = curr.coordinates?.[0] || curr.longitude;

          if (lat1 && lng1 && lat2 && lng2) {
            totalDistance += calculateDistance(lat1, lng1, lat2, lng2);
          }

          const speed = curr.speed || 0;
          if (speed > 0) {
            speedSum += speed;
            speedCount++;
            if (speed > maxSpeed) maxSpeed = speed;
          }
        }
      }

      if (attendance.checkOutTime) {
        totalDuration +=
          (attendance.checkOutTime - attendance.checkInTime) / (1000 * 60);
      } else if (attendance.checkInTime) {
        totalDuration += (Date.now() - attendance.checkInTime) / (1000 * 60);
      }
    }

    res.json({
      success: true,
      distance: totalDistance / 1000,
      duration: Math.round(totalDuration),
      avgSpeed: speedCount > 0 ? speedSum / speedCount : 0,
      maxSpeed: maxSpeed,
      days: attendances.length,
    });
  } catch (error) {
    console.error("❌ Employee stats error:", error);
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});

module.exports = router;
