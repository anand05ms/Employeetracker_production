// backend/routes/enhanced_attendance.js
// ENHANCED: Attendance routes with speed, altitude, accuracy support

const express = require("express");
const router = express.Router();
const auth = require("../middleware/auth");
const Attendance = require("../models/Attendance");

// POST /api/attendance/location-enhanced
// Update location with enhanced data (speed, altitude, accuracy)
router.post("/location-enhanced", auth, async (req, res) => {
  try {
    const employeeId = req.user.id;
    const {
      latitude,
      longitude,
      address,
      speed = 0,
      altitude = 0,
      accuracy = 0,
      heading = 0,
      timestamp,
    } = req.body;

    console.log(`📍 Enhanced location from ${req.user.name}:`, {
      lat: latitude,
      lng: longitude,
      speed: `${speed.toFixed(1)} km/h`,
      altitude: `${altitude.toFixed(1)}m`,
      accuracy: `±${accuracy.toFixed(1)}m`,
    });

    // Find today's active attendance
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const attendance = await Attendance.findOne({
      employee: employeeId,
      checkInTime: { $gte: today },
      checkOutTime: null,
    });

    if (!attendance) {
      console.log("⚠️ No active attendance found");
      return res.status(400).json({
        success: false,
        message: "No active check-in found",
      });
    }

    // Create location update object
    const locationUpdate = {
      type: "Point",
      coordinates: [longitude, latitude],
      latitude: latitude,
      longitude: longitude,
      address: address,
      speed: speed,
      altitude: altitude,
      accuracy: accuracy,
      heading: heading,
      timestamp: timestamp ? new Date(timestamp) : new Date(),
    };

    // Add to route
    attendance.route.push(locationUpdate);

    // Update latest location
    attendance.latestLocation = locationUpdate;

    await attendance.save();

    console.log(
      `✅ Location saved. Route has ${attendance.route.length} points`,
    );

    res.json({
      success: true,
      message: "Location updated",
      routePoints: attendance.route.length,
    });
  } catch (error) {
    console.error("❌ Enhanced location error:", error);
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});

// GET /api/attendance/status
// Get current attendance status
router.get("/status", auth, async (req, res) => {
  try {
    const employeeId = req.user.id;

    // Find today's attendance
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const attendance = await Attendance.findOne({
      employee: employeeId,
      checkInTime: { $gte: today },
    }).sort({ checkInTime: -1 });

    if (!attendance) {
      return res.json({
        success: true,
        isCheckedIn: false,
        attendance: null,
      });
    }

    res.json({
      success: true,
      isCheckedIn: attendance.checkOutTime === null,
      attendance: {
        id: attendance._id,
        checkInTime: attendance.checkInTime,
        checkOutTime: attendance.checkOutTime,
        checkInLocation: attendance.checkInLocation,
        latestLocation: attendance.latestLocation,
        routePoints: attendance.route?.length || 0,
      },
    });
  } catch (error) {
    console.error("❌ Status error:", error);
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});

// POST /api/attendance/check-in
// Check in with location
router.post("/check-in", auth, async (req, res) => {
  try {
    const employeeId = req.user.id;
    const { latitude, longitude, address } = req.body;

    console.log(`👤 ${req.user.name} checking in at ${latitude}, ${longitude}`);

    // Check if already checked in today
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const existingAttendance = await Attendance.findOne({
      employee: employeeId,
      checkInTime: { $gte: today },
      checkOutTime: null,
    });

    if (existingAttendance) {
      return res.status(400).json({
        success: false,
        message: "Already checked in today",
      });
    }

    // Create new attendance
    const attendance = new Attendance({
      employee: employeeId,
      checkInTime: new Date(),
      checkInLocation: {
        type: "Point",
        coordinates: [longitude, latitude],
        address: address,
      },
      route: [],
      latestLocation: {
        type: "Point",
        coordinates: [longitude, latitude],
        latitude: latitude,
        longitude: longitude,
        address: address,
        timestamp: new Date(),
      },
    });

    await attendance.save();

    console.log(`✅ ${req.user.name} checked in successfully`);

    res.json({
      success: true,
      message: "Checked in successfully",
      attendance: {
        id: attendance._id,
        checkInTime: attendance.checkInTime,
      },
    });
  } catch (error) {
    console.error("❌ Check-in error:", error);
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});

// POST /api/attendance/check-out
// Check out with location
router.post("/check-out", auth, async (req, res) => {
  try {
    const employeeId = req.user.id;
    const { latitude, longitude, address } = req.body;

    console.log(
      `👤 ${req.user.name} checking out at ${latitude}, ${longitude}`,
    );

    // Find today's active attendance
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const attendance = await Attendance.findOne({
      employee: employeeId,
      checkInTime: { $gte: today },
      checkOutTime: null,
    });

    if (!attendance) {
      return res.status(400).json({
        success: false,
        message: "No active check-in found",
      });
    }

    // Update checkout
    attendance.checkOutTime = new Date();
    attendance.checkOutLocation = {
      type: "Point",
      coordinates: [longitude, latitude],
      address: address,
    };

    await attendance.save();

    console.log(`✅ ${req.user.name} checked out successfully`);

    res.json({
      success: true,
      message: "Checked out successfully",
      attendance: {
        id: attendance._id,
        checkInTime: attendance.checkInTime,
        checkOutTime: attendance.checkOutTime,
        duration: Math.round(
          (attendance.checkOutTime - attendance.checkInTime) / (1000 * 60),
        ), // minutes
      },
    });
  } catch (error) {
    console.error("❌ Check-out error:", error);
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});

// GET /api/attendance/route/:attendanceId
// Get route for specific attendance (for replay)
router.get("/route/:attendanceId", auth, async (req, res) => {
  try {
    const { attendanceId } = req.params;

    const attendance = await Attendance.findById(attendanceId).populate(
      "employee",
      "name email",
    );

    if (!attendance) {
      return res.status(404).json({
        success: false,
        message: "Attendance not found",
      });
    }

    // Check authorization (employee can see own, admin can see all)
    if (
      req.user.role !== "admin" &&
      attendance.employee._id.toString() !== req.user.id
    ) {
      return res.status(403).json({
        success: false,
        message: "Unauthorized",
      });
    }

    res.json({
      success: true,
      route: attendance.route || [],
      checkInTime: attendance.checkInTime,
      checkOutTime: attendance.checkOutTime,
      employee: {
        name: attendance.employee.name,
        id: attendance.employee._id,
      },
    });
  } catch (error) {
    console.error("❌ Route error:", error);
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});

module.exports = router;
