// routes/employee.js
const express = require("express");
const router = express.Router();
const {
  checkIn,
  checkOut,
  updateLocation,
  updateLocationEnhanced,
  getMyAttendance,
  getMyStatus,
  getMyStats,
  getTodayTimeline,
} = require("../controllers/employeeController");

const { protect, authorize } = require("../middleware/auth");

// All routes are protected and employee-only
router.use(protect);
router.use(authorize("EMPLOYEE"));
router.post("/check-in", checkIn);
router.post("/check-out", checkOut);
router.post("/location", updateLocation);
router.get("/attendance", getMyAttendance);
router.get("/status", getMyStatus);
router.post("/location-enhanced", updateLocationEnhanced);
router.get("/stats", getMyStats);
router.get("/timeline", getTodayTimeline);
module.exports = router;
