#!/usr/bin/env node
/**
 * Seed Firestore with popular US golf courses.
 *
 * Usage:
 *   cd firebase
 *   npm install firebase-admin   (if not already)
 *   export GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccountKey.json
 *   node seed-courses.js
 *
 * Or from the Firebase console, import courses.json into the "courses" collection.
 */

const admin = require("firebase-admin");

// Initialize — uses GOOGLE_APPLICATION_CREDENTIALS env var or default credentials
if (!admin.apps.length) {
  admin.initializeApp();
}
const db = admin.firestore();

function defaultHoles(par, count = 18) {
  const basePar = Math.floor(par / count);
  const remainder = par % count;
  return Array.from({ length: count }, (_, i) => ({
    number: i + 1,
    par: basePar + (i < remainder ? 1 : 0),
    yardage: 0,
    handicapRank: i + 1,
  }));
}

const courses = [
  { name: "Pebble Beach Golf Links", city: "Pebble Beach", state: "CA", country: "US", latitude: 36.5684, longitude: -121.9506, courseRating: 75.5, slopeRating: 145, par: 72 },
  { name: "Augusta National Golf Club", city: "Augusta", state: "GA", country: "US", latitude: 33.503, longitude: -82.0201, courseRating: 76.2, slopeRating: 148, par: 72 },
  { name: "Pinehurst No. 2", city: "Pinehurst", state: "NC", country: "US", latitude: 35.1943, longitude: -79.4703, courseRating: 75.3, slopeRating: 141, par: 72 },
  { name: "TPC Sawgrass (Stadium)", city: "Ponte Vedra Beach", state: "FL", country: "US", latitude: 30.1975, longitude: -81.3942, courseRating: 76.4, slopeRating: 155, par: 72 },
  { name: "Torrey Pines (South)", city: "La Jolla", state: "CA", country: "US", latitude: 32.8959, longitude: -117.2526, courseRating: 76.8, slopeRating: 144, par: 72 },
  { name: "Bethpage Black", city: "Farmingdale", state: "NY", country: "US", latitude: 40.7396, longitude: -73.4538, courseRating: 77.5, slopeRating: 155, par: 71 },
  { name: "Whistling Straits (Straits)", city: "Sheboygan", state: "WI", country: "US", latitude: 43.8487, longitude: -87.7237, courseRating: 76.7, slopeRating: 152, par: 72 },
  { name: "Kiawah Island (Ocean)", city: "Kiawah Island", state: "SC", country: "US", latitude: 32.6085, longitude: -80.0976, courseRating: 77.2, slopeRating: 155, par: 72 },
  { name: "Bandon Dunes", city: "Bandon", state: "OR", country: "US", latitude: 43.1866, longitude: -124.3729, courseRating: 74.1, slopeRating: 143, par: 72 },
  { name: "Streamsong (Red)", city: "Bowling Green", state: "FL", country: "US", latitude: 27.6348, longitude: -81.5279, courseRating: 73.8, slopeRating: 140, par: 72 },
  { name: "Harbour Town Golf Links", city: "Hilton Head Island", state: "SC", country: "US", latitude: 32.1361, longitude: -80.8253, courseRating: 74.0, slopeRating: 146, par: 71 },
  { name: "Congressional (Blue)", city: "Bethesda", state: "MD", country: "US", latitude: 38.9857, longitude: -77.1598, courseRating: 76.1, slopeRating: 149, par: 72 },
  { name: "Muirfield Village", city: "Dublin", state: "OH", country: "US", latitude: 40.0994, longitude: -83.1816, courseRating: 76.8, slopeRating: 149, par: 72 },
  { name: "Riviera Country Club", city: "Pacific Palisades", state: "CA", country: "US", latitude: 34.0481, longitude: -118.5016, courseRating: 75.6, slopeRating: 148, par: 71 },
  { name: "Merion Golf Club (East)", city: "Ardmore", state: "PA", country: "US", latitude: 40.0016, longitude: -75.3168, courseRating: 74.9, slopeRating: 147, par: 70 },
  { name: "Oakmont Country Club", city: "Oakmont", state: "PA", country: "US", latitude: 40.5217, longitude: -79.8281, courseRating: 77.5, slopeRating: 155, par: 71 },
  { name: "Winged Foot (West)", city: "Mamaroneck", state: "NY", country: "US", latitude: 40.9579, longitude: -73.7365, courseRating: 76.5, slopeRating: 150, par: 72 },
  { name: "Shinnecock Hills", city: "Southampton", state: "NY", country: "US", latitude: 40.8921, longitude: -72.4395, courseRating: 76.4, slopeRating: 148, par: 70 },
  { name: "Erin Hills", city: "Erin", state: "WI", country: "US", latitude: 43.211, longitude: -88.3252, courseRating: 76.6, slopeRating: 147, par: 72 },
  { name: "Chambers Bay", city: "University Place", state: "WA", country: "US", latitude: 47.2013, longitude: -122.5706, courseRating: 75.5, slopeRating: 144, par: 72 },
  // Public-accessible / popular courses
  { name: "Cabot Cliffs", city: "Inverness", state: "NS", country: "CA", latitude: 46.2224, longitude: -61.3862, courseRating: 74.5, slopeRating: 142, par: 72 },
  { name: "Pacific Dunes", city: "Bandon", state: "OR", country: "US", latitude: 43.1866, longitude: -124.3729, courseRating: 73.2, slopeRating: 140, par: 71 },
  { name: "Sand Valley", city: "Nekoosa", state: "WI", country: "US", latitude: 44.1254, longitude: -89.9429, courseRating: 74.6, slopeRating: 139, par: 72 },
  { name: "Arcadia Bluffs", city: "Arcadia", state: "MI", country: "US", latitude: 44.4962, longitude: -86.2487, courseRating: 74.9, slopeRating: 143, par: 72 },
  { name: "Scottsdale National", city: "Scottsdale", state: "AZ", country: "US", latitude: 33.7148, longitude: -111.9277, courseRating: 73.8, slopeRating: 138, par: 72 },
  { name: "We-Ko-Pa (Saguaro)", city: "Fort McDowell", state: "AZ", country: "US", latitude: 33.63, longitude: -111.68, courseRating: 74.3, slopeRating: 139, par: 72 },
  { name: "TPC Scottsdale (Stadium)", city: "Scottsdale", state: "AZ", country: "US", latitude: 33.6416, longitude: -111.907, courseRating: 74.9, slopeRating: 143, par: 71 },
  { name: "Bay Hill Club & Lodge", city: "Orlando", state: "FL", country: "US", latitude: 28.4612, longitude: -81.5174, courseRating: 75.1, slopeRating: 141, par: 72 },
  { name: "Valhalla Golf Club", city: "Louisville", state: "KY", country: "US", latitude: 38.2437, longitude: -85.5019, courseRating: 76.9, slopeRating: 151, par: 72 },
  { name: "East Lake Golf Club", city: "Atlanta", state: "GA", country: "US", latitude: 33.7423, longitude: -84.3162, courseRating: 75.4, slopeRating: 148, par: 72 },
  // Everyday popular public courses
  { name: "Cog Hill (Dubsdread No. 4)", city: "Lemont", state: "IL", country: "US", latitude: 41.6106, longitude: -87.9981, courseRating: 75.8, slopeRating: 142, par: 72 },
  { name: "Pinehurst No. 4", city: "Pinehurst", state: "NC", country: "US", latitude: 35.1943, longitude: -79.47, courseRating: 74.1, slopeRating: 138, par: 72 },
  { name: "Streamsong (Blue)", city: "Bowling Green", state: "FL", country: "US", latitude: 27.6348, longitude: -81.5279, courseRating: 74.1, slopeRating: 142, par: 72 },
  { name: "Mammoth Dunes", city: "Nekoosa", state: "WI", country: "US", latitude: 44.1254, longitude: -89.9429, courseRating: 74.0, slopeRating: 137, par: 73 },
  { name: "Rustic Canyon Golf Course", city: "Moorpark", state: "CA", country: "US", latitude: 34.2847, longitude: -118.7762, courseRating: 72.8, slopeRating: 133, par: 72 },
  { name: "Sheep Ranch", city: "Bandon", state: "OR", country: "US", latitude: 43.1866, longitude: -124.37, courseRating: 72.5, slopeRating: 131, par: 71 },
  { name: "Wild Horse Golf Club", city: "Gothenburg", state: "NE", country: "US", latitude: 40.93, longitude: -100.16, courseRating: 72.1, slopeRating: 130, par: 72 },
  { name: "Barefoot Resort (Dye)", city: "North Myrtle Beach", state: "SC", country: "US", latitude: 33.85, longitude: -78.72, courseRating: 74.2, slopeRating: 143, par: 72 },
  { name: "Caledonia Golf & Fish Club", city: "Pawleys Island", state: "SC", country: "US", latitude: 33.43, longitude: -79.12, courseRating: 73.4, slopeRating: 139, par: 72 },
  { name: "Tobacco Road Golf Club", city: "Sanford", state: "NC", country: "US", latitude: 35.49, longitude: -79.22, courseRating: 72.6, slopeRating: 150, par: 71 },
  { name: "The Links at Spanish Bay", city: "Pebble Beach", state: "CA", country: "US", latitude: 36.59, longitude: -121.96, courseRating: 74.0, slopeRating: 141, par: 72 },
  { name: "Spyglass Hill Golf Course", city: "Pebble Beach", state: "CA", country: "US", latitude: 36.58, longitude: -121.95, courseRating: 75.5, slopeRating: 148, par: 72 },
  { name: "Pasatiempo Golf Club", city: "Santa Cruz", state: "CA", country: "US", latitude: 36.99, longitude: -122.04, courseRating: 73.4, slopeRating: 143, par: 71 },
  { name: "Barnbougle Dunes", city: "Bridport", state: "TAS", country: "AU", latitude: -41.04, longitude: 146.95, courseRating: 73.0, slopeRating: 138, par: 71 },
  { name: "Whistling Straits (Irish)", city: "Sheboygan", state: "WI", country: "US", latitude: 43.849, longitude: -87.724, courseRating: 74.6, slopeRating: 143, par: 72 },
  { name: "Blackwolf Run (River)", city: "Kohler", state: "WI", country: "US", latitude: 43.75, longitude: -87.77, courseRating: 75.9, slopeRating: 151, par: 72 },
  { name: "Troon North (Monument)", city: "Scottsdale", state: "AZ", country: "US", latitude: 33.77, longitude: -111.92, courseRating: 73.9, slopeRating: 147, par: 72 },
  { name: "Grayhawk (Raptor)", city: "Scottsdale", state: "AZ", country: "US", latitude: 33.68, longitude: -111.91, courseRating: 73.0, slopeRating: 139, par: 72 },
  { name: "Coore & Crenshaw at Lido", city: "Sand Point", state: "NY", country: "US", latitude: 40.85, longitude: -73.71, courseRating: 74.3, slopeRating: 142, par: 72 },
  { name: "Crystal Downs Country Club", city: "Frankfort", state: "MI", country: "US", latitude: 44.64, longitude: -86.22, courseRating: 73.2, slopeRating: 138, par: 70 },
];

async function seed() {
  const batch = db.batch();
  let count = 0;

  for (const c of courses) {
    const ref = db.collection("courses").doc();
    batch.set(ref, {
      ...c,
      nameLowercase: c.name.toLowerCase(),
      holes: defaultHoles(c.par),
    });
    count++;
    // Firestore batch limit is 500
    if (count % 400 === 0) {
      await batch.commit();
      console.log(`Committed ${count} courses...`);
    }
  }

  await batch.commit();
  console.log(`✅ Seeded ${count} courses into Firestore "courses" collection.`);
}

seed().catch(console.error);
