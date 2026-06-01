const Datastore = require('nedb-promises');
const path = require('path');
const fs = require('fs');
const bcrypt = require('bcryptjs');

const DB_PATH = process.env.DB_PATH || __dirname;
fs.mkdirSync(DB_PATH, { recursive: true });

const usersDB = Datastore.create({ filename: path.join(DB_PATH, 'users.db'), autoload: true });
const servicesDB = Datastore.create({ filename: path.join(DB_PATH, 'services.db'), autoload: true });
const bookingsDB = Datastore.create({ filename: path.join(DB_PATH, 'bookings.db'), autoload: true });
const reviewsDB = Datastore.create({ filename: path.join(DB_PATH, 'reviews.db'), autoload: true });
const chatsDB = Datastore.create({ filename: path.join(DB_PATH, 'chats.db'), autoload: true });
const messagesDB = Datastore.create({ filename: path.join(DB_PATH, 'messages.db'), autoload: true });
const auditLogsDB = Datastore.create({ filename: path.join(DB_PATH, 'audit_logs.db'), autoload: true });
const notificationsDB = Datastore.create({ filename: path.join(DB_PATH, 'notifications.db'), autoload: true });

const seedServices = async () => {
  const count = await servicesDB.count({});
  if (count === 0) {
    const providers = await usersDB.find({ role: 'provider' });
    const providerMap = new Map(providers.map((provider) => [provider.name, provider._id]));
    const resolveProvider = (name) => providerMap.get(name) ?? null;

    const professionalServices = [
      {
        title: "Expert Plumbing & Repair",
        category: "Plumbing",
        provider: "Abebe Plumbing Solutions",
        provider_id: resolveProvider("Abebe Plumbing Solutions"),
        rating: 4.8,
        reviewsCount: 156,
        price: "Starts from $45/hr",
        description: "Specializing in all plumbing needs, from emergency leak repair to bathroom installations. 24/7 service available.",
        image: "assets/images/photo-1.jpg",
        location: "Bole, Addis Ababa",
        verified: true,
        contact_phone: "+251 911 234 567",
        contact_whatsapp: "+251 911 234 567",
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      },
      {
        title: "Garden & Landscape Design",
        category: "Gardening",
        provider: "Kebede Green Landscapes",
        provider_id: resolveProvider("Kebede Green Landscapes"),
        rating: 4.5,
        reviewsCount: 89,
        price: "Starts from $35/hr",
        description: "Transform your outdoor space with our expert landscaping, lawn maintenance, and garden design services.",
        image: "assets/images/oto-2.jpg",
        location: "CMC, Addis Ababa",
        verified: true,
        contact_phone: "+251 912 345 678",
        contact_whatsapp: "+251 912 345 678",
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      },
      {
        title: "Professional Electrician",
        category: "Electrician",
        provider: "Dawit Electrical Works",
        provider_id: resolveProvider("Dawit Electrical Works"),
        rating: 4.9,
        reviewsCount: 230,
        price: "Starts from $55/hr",
        description: "Certified electricians providing safe and reliable electrical installations, wiring, and repairs.",
        image: "assets/images/photo-3.jpg",
        location: "Saris, Addis Ababa",
        verified: true,
        contact_phone: "+251 913 456 789",
        contact_whatsapp: "+251 913 456 789",
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      },
      {
        title: "Deep House Cleaning",
        category: "Cleaning",
        provider: "CleanPro Services",
        provider_id: resolveProvider("CleanPro Services"),
        rating: 4.7,
        reviewsCount: 112,
        price: "Starts from $25/hr",
        description: "Premium house and office cleaning services using eco-friendly products.",
        image: "assets/images/photo-4.jpg",
        location: "Piyassa, Addis Ababa",
        verified: false,
        contact_phone: "+251 914 567 890",
        contact_whatsapp: "+251 914 567 890",
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      },
      {
        title: "Interior & Exterior Painting",
        category: "Painting",
        provider: "ColorMaster Designs",
        provider_id: resolveProvider("ColorMaster Designs"),
        rating: 4.6,
        reviewsCount: 65,
        price: "Starts from $40/hr",
        description: "Professional painting services for residential and commercial properties.",
        image: "assets/images/photo-1.jpg",
        location: "Kality, Addis Ababa",
        verified: true,
        contact_phone: "+251 915 678 901",
        contact_whatsapp: "+251 915 678 901",
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      },
    ];
    await servicesDB.insert(professionalServices);
    console.log('Database seeded with professional services.');
  }
};

const seedDemoUsers = async () => {
  const passwordHash = await bcrypt.hash('password123', 12);
  const demoUsers = [
    {
      name: 'Abebe Plumbing Solutions',
      email: 'abebe@localconnect.et',
      phone: '+251911234567',
      role: 'provider',
      is_verified: true,
    },
    {
      name: 'Kebede Green Landscapes',
      email: 'kebede@localconnect.et',
      phone: '+251912345678',
      role: 'provider',
      is_verified: true,
    },
    {
      name: 'Dawit Electrical Works',
      email: 'dawit@localconnect.et',
      phone: '+251913456789',
      role: 'provider',
      is_verified: true,
    },
    {
      name: 'CleanPro Services',
      email: 'cleanpro@localconnect.et',
      phone: '+251914567890',
      role: 'provider',
      is_verified: false,
    },
    {
      name: 'ColorMaster Designs',
      email: 'colormaster@localconnect.et',
      phone: '+251915678901',
      role: 'provider',
      is_verified: true,
    },
    {
      name: 'LocalConnect Admin',
      email: 'admin@localconnect.et',
      phone: '+251900000001',
      role: 'admin',
      is_verified: true,
    },
    {
      name: 'Mulu Customer',
      email: 'customer@localconnect.et',
      phone: '+251900000002',
      role: 'customer',
      is_verified: false,
    },
  ];

  for (const demoUser of demoUsers) {
    const existing = await usersDB.findOne({ email: demoUser.email });
    if (!existing) {
      await usersDB.insert({
        name: demoUser.name,
        email: demoUser.email,
        phone: demoUser.phone,
        password_hash: passwordHash,
        role: demoUser.role,
        profile_image: null,
        is_verified: demoUser.is_verified,
        is_active: true,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      });
    }
  }
};

module.exports = { usersDB, servicesDB, bookingsDB, reviewsDB, chatsDB, messagesDB, auditLogsDB, notificationsDB, seedServices, seedDemoUsers };
