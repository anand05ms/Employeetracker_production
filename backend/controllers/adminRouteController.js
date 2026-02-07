// const Location = require("../models/Location");

// /**
//  * Calculate distance in meters (Haversine)
//  */
// const distance = (lat1, lon1, lat2, lon2) => {
//   const R = 6371e3;
//   const toRad = (x) => (x * Math.PI) / 180;

//   const dLat = toRad(lat2 - lat1);
//   const dLon = toRad(lon2 - lon1);

//   const a =
//     Math.sin(dLat / 2) ** 2 +
//     Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;

//   return 2 * R * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
// };

// /**
//  * GET DRIVER ROUTE + STOPS
//  */
// exports.getEmployeeRoute = async (req, res) => {
//   try {
//     const { employeeId } = req.params;
//     const { date } = req.query;

//     if (!date) {
//       return res.status(400).json({
//         success: false,
//         message: "Date is required",
//       });
//     }

//     const locations = await Location.find({
//       employeeId,
//       timestamp: {
//         $gte: new Date(`${date}T00:00:00`),
//         $lte: new Date(`${date}T23:59:59`),
//       },
//     }).sort({ timestamp: 1 });

//     if (locations.length === 0) {
//       return res.json({
//         success: true,
//         data: { route: [], stops: [], summary: {} },
//       });
//     }

//     // ---------------- ROUTE ----------------
//     const route = locations.map((l) => ({
//       lat: l.location.coordinates[1],
//       lng: l.location.coordinates[0],
//       time: l.timestamp.toISOString().substring(11, 19),
//     }));

//     // ---------------- STOPS ----------------
//     const stops = [];
//     let start = null;

//     for (let i = 1; i < locations.length; i++) {
//       const prev = locations[i - 1];
//       const curr = locations[i];

//       const d = distance(
//         prev.location.coordinates[1],
//         prev.location.coordinates[0],
//         curr.location.coordinates[1],
//         curr.location.coordinates[0],
//       );

//       const timeDiff =
//         (new Date(curr.timestamp) - new Date(prev.timestamp)) / 60000;

//       if (d < 20) {
//         if (!start) start = prev;
//       } else {
//         if (start) {
//           const duration =
//             (new Date(prev.timestamp) - new Date(start.timestamp)) / 60000;

//           if (duration >= 5) {
//             stops.push({
//               lat: start.location.coordinates[1],
//               lng: start.location.coordinates[0],
//               from: start.timestamp.toISOString().substring(11, 16),
//               to: prev.timestamp.toISOString().substring(11, 16),
//               durationMinutes: Math.round(duration),
//             });
//           }
//           start = null;
//         }
//       }
//     }

//     res.json({
//       success: true,
//       data: {
//         route,
//         stops,
//         summary: {
//           startTime: route[0].time,
//           endTime: route[route.length - 1].time,
//         },
//       },
//     });
//   } catch (err) {
//     res.status(500).json({
//       success: false,
//       message: err.message,
//     });
//   }
// };

const Location = require("../models/Location");

/**
 * Haversine distance (meters)
 */
const distance = (lat1, lon1, lat2, lon2) => {
  const R = 6371e3;
  const toRad = (x) => (x * Math.PI) / 180;

  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);

  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;

  return 2 * R * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
};

/**
 * GET EMPLOYEE ROUTE (BY DATE)
 */
exports.getEmployeeRoute = async (req, res) => {
  try {
    const { employeeId } = req.params;
    const { date } = req.query;

    if (!date) {
      return res.status(400).json({
        success: false,
        message: "Date is required",
      });
    }

    const start = new Date(`${date}T00:00:00`);
    const end = new Date(`${date}T23:59:59`);

    const locations = await Location.find({
      employeeId,
      timestamp: { $gte: start, $lte: end },
    }).sort({ timestamp: 1 });

    if (!locations.length) {
      return res.json({
        success: true,
        data: { route: [], stops: [], summary: {} },
      });
    }

    const route = locations
      .filter(
        (l) =>
          l.location &&
          Array.isArray(l.location.coordinates) &&
          l.location.coordinates.length === 2,
      )
      .map((l) => ({
        lat: l.location.coordinates[1],
        lng: l.location.coordinates[0],
        time: l.timestamp.toISOString().substring(11, 19),
      }));

    if (route.length === 0) {
      return res.json({
        success: true,
        data: { route: [], stops: [], summary: {} },
      });
    }

    const stops = [];
    let startStop = null;

    for (let i = 1; i < locations.length; i++) {
      const prev = locations[i - 1];
      const curr = locations[i];

      const d = distance(
        prev.location.coordinates[1],
        prev.location.coordinates[0],
        curr.location.coordinates[1],
        curr.location.coordinates[0],
      );

      const minutes =
        (new Date(curr.timestamp) - new Date(prev.timestamp)) / 60000;

      if (d < 20) {
        if (!startStop) startStop = prev;
      } else if (startStop) {
        const duration =
          (new Date(prev.timestamp) - new Date(startStop.timestamp)) / 60000;

        if (duration >= 5) {
          stops.push({
            lat: startStop.location.coordinates[1],
            lng: startStop.location.coordinates[0],
            from: startStop.timestamp.toISOString().substring(11, 16),
            to: prev.timestamp.toISOString().substring(11, 16),
            durationMinutes: Math.round(duration),
          });
        }
        startStop = null;
      }
    }

    res.json({
      success: true,
      data: {
        route,
        stops,
        summary: {
          startTime: route[0].time,
          endTime: route[route.length - 1].time,
        },
      },
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      message: err.message,
    });
  }
};
