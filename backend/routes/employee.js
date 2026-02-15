const express = require("express");
const router = express.Router();

const {
  checkIn,
  checkOut,
  updateLocation,
  getMyStatus,
  getMyStats,
  getTodayTimeline,
} = require("../controllers/employeeController");

const { protect, authorize } = require("../middleware/auth");

router.use(protect);
router.use(authorize("EMPLOYEE"));

router.post("/check-in", checkIn);
router.post("/check-out", checkOut);
router.post("/location", updateLocation);

router.get("/status", getMyStatus);
router.get("/stats", getMyStats);
router.get("/timeline", getTodayTimeline);

module.exports = router;
