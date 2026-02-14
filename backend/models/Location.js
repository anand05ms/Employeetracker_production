// // models/Location.js
// const mongoose = require("mongoose");

// const locationSchema = new mongoose.Schema({
//   employeeId: {
//     type: mongoose.Schema.Types.ObjectId,
//     ref: "User",
//     required: true,
//     index: true,
//   },
//   location: {
//     type: {
//       type: String,
//       enum: ["Point"],
//       default: "Point",
//     },
//     coordinates: {
//       type: [Number],
//       required: true,
//     },
//   },
//   address: {
//     type: String,
//     trim: true,
//   },
//   accuracy: {
//     type: Number,
//   },
//   speed: {
//     type: Number,
//     default: 0,
//   },
//   heading: {
//     type: Number,
//   },
//   timestamp: {
//     type: Date,
//     default: Date.now,
//     // Removed index: true from here (keeping it only in schema.index below)
//   },
//   status: {
//     type: String,
//     enum: ["ACTIVE", "IDLE", "OFFLINE"],
//     default: "ACTIVE",
//   },
//   isInOffice: {
//     type: Boolean,
//     default: false,
//   },
//   batteryLevel: {
//     type: Number,
//     min: 0,
//     max: 100,
//   },
// });

// // Create geospatial index for location queries
// locationSchema.index({ location: "2dsphere" });
// LocationSchema.index({ employeeId: 1, timestamp: 1 });
// // Compound index for efficient queries
// locationSchema.index({ employeeId: 1, timestamp: -1 });

// // Auto-delete old location records after 30 days (optional)
// // Comment out if you want to keep all history
// // locationSchema.index({ timestamp: 1 }, { expireAfterSeconds: 2592000 });

// module.exports = mongoose.model("Location", locationSchema);
// const mongoose = require("mongoose");

// const locationSchema = new mongoose.Schema({
//   employeeId: {
//     type: mongoose.Schema.Types.ObjectId,
//     ref: "User",
//     required: true,
//     index: true,
//   },

//   location: {
//     type: {
//       type: String,
//       enum: ["Point"],
//       default: "Point",
//     },
//     coordinates: {
//       type: [Number],
//       required: true,
//     },
//   },

//   address: {
//     type: String,
//     trim: true,
//   },

//   accuracy: Number,

//   speed: {
//     type: Number,
//     default: 0,
//   },

//   heading: Number,

//   timestamp: {
//     type: Date,
//     default: Date.now,
//   },

//   status: {
//     type: String,
//     enum: ["ACTIVE", "IDLE", "OFFLINE"],
//     default: "ACTIVE",
//   },

//   isInOffice: {
//     type: Boolean,
//     default: false,
//   },

//   batteryLevel: {
//     type: Number,
//     min: 0,
//     max: 100,
//   },
// });

// /* ✅ INDEXES */

// // Geo index
// locationSchema.index({ location: "2dsphere" });

// // Query performance index
// locationSchema.index({ employeeId: 1, timestamp: -1 });

// module.exports = mongoose.model("Location", locationSchema);

const mongoose = require("mongoose");

const locationSchema = new mongoose.Schema({
  employeeId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true,
    index: true,
  },

  location: {
    type: {
      type: String,
      enum: ["Point"],
      required: true,
    },
    coordinates: {
      type: [Number], // [lng, lat]
      required: true,
    },
  },

  address: {
    type: String,
    default: "Unknown",
  },

  speed: {
    type: Number,
    default: 0,
  },

  altitude: {
    type: Number,
    default: 0,
  },

  accuracy: {
    type: Number,
    default: 0,
  },

  heading: {
    type: Number,
    default: 0,
  },

  status: {
    type: String,
    default: "ACTIVE",
  },

  isInOffice: {
    type: Boolean,
    default: false,
  },

  timestamp: {
    type: Date,
    required: true,
    index: true,
  },

  createdAt: {
    type: Date,
    default: Date.now,
    expires: 60 * 60 * 24 * 7, // auto delete after 7 days
  },
});

locationSchema.index({ location: "2dsphere" });

module.exports = mongoose.model("Location", locationSchema);
