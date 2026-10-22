// Runs automatically when mongo container starts fresh
// Add indexes, collections, or seed data here

db = db.getSiblingDB("devdb");

db.createCollection("users");
db.users.createIndex({ email: 1 }, { unique: true });

// db.createCollection("posts");
// db.posts.createIndex({ createdAt: -1 });
