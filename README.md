# README

# 🌟 Free Quran Distribution System 🌟

> "*Whoever guides [another] to something good has the reward of one who does it.*" - Prophet Muhammad (PBUH)

A comprehensive, modern web application for global Quran distribution, built with Rails 7, featuring international localization, professional admin dashboard, and real-time analytics.

## 🚀 Features Overview

### 🌍 **Global Accessibility**
- **27 International Countries** Support (Pakistan, India, UAE, Saudi Arabia, USA, UK, etc.)
- **Dynamic State/District Selection** based on country choice
- **Automatic Phone Number Formatting** with country-specific patterns
- **International Shipping Addresses** with proper validation

### 📱 **Modern User Experience**
- **Responsive Design** - Works perfectly on desktop, tablet, and mobile
- **AJAX-Powered Forms** - Instant form submissions without page reloads
- **Real-time Feedback** - Success notifications and loading states
- **Professional UI/UX** - Built with Tailwind CSS and Font Awesome

### 👨‍💼 **Complete Admin Management**
- **Order Lifecycle Management** - Handle orders from placement to delivery
- **Real-time Analytics** - Live dashboards with charts and counters
- **AJAX Filtering & Sorting** - Instant order management without page reloads
- **Status Management** - One-click status updates with visual feedback
- **Quran Inventory Management** - Add, edit, delete Quran books with images

### 📊 **Advanced Analytics Dashboard**
- **Real-time Metrics** - Order counts, country distribution, stock levels
- **Interactive Charts** - Monitoring trends and performance
- **Geographic Heatmaps** - Visual order distribution worldwide
- **Stock Alerts** - Automatic notifications for low inventory
- **Performance Tracking** - Conversion funnels and monthly reports

## 🛠️ Technology Stack

- **Backend:** Ruby on Rails 7.2
- **Frontend:** HTML5, Tailwind CSS, JavaScript/AJAX, Font Awesome Icons
- **Database:** PostgreSQL
- **Authentication:** Devise (Admin-only authentication)
- **Charts:** Chart.js
- **Maps:** Leaflet.js for interactive heatmaps
- **Background Jobs:** ActiveJob with free Quran delivery broadcasts
- **File Uploads:** ActiveStorage (for Quran book images)

## 📦 Installation & Setup

### Prerequisites
- Ruby 3.1+
- PostgreSQL
- Node.js & Yarn
- Redis (optional, for advanced features)

### Installation Steps

1. **Clone the Repository**
```bash
git clone [your-repo-url]
cd order_free_quran
```

2. **Install Dependencies**
```bash
bundle install
yarn install
```

3. **Database Setup**
```bash
rails db:create
rails db:migrate
rails db:seed  # Loads sample data for testing
```

4. **Start the Server**
```bash
bin/dev  # Starts Rails server with Hotwire/Turbo
```

5. **Access the Application**
```
Main Site: http://localhost:3000
Admin Panel: http://localhost:3000/admin/sign_in
```

### Sample Admin Credentials
```
Email: admin@example.com
Password: password123
```

## 🎯 Usage Guide

### 📝 For Quran Seekers (Public Users)

#### Ordering a Free Quran Copy
1. **Visit the Homepage**
   - Browse available Quran books with high-quality images
   - Choose a book you're interested in (all FREE!)

2. **Fill the Order Form**
   - Visit `http://localhost:3000/new`
   - Select your **Country** from dropdown (shows 27+ countries with flags)
   - **States/Regions** automatically load based on your country selection
   - Phone number formats automatically according to your country
   - Fill in your shipping address details

3. **Submit Your Order**
   - Click "Submit Order" - processed with AJAX (no page reload!)
   - Receive beautiful confirmation page with Islamic inspiration
   - Order immediately appears in admin panel for processing

#### Supported Countries
🇵🇰 Pakistan 🇮🇳 India 🇦🇪 UAE 🇸🇦 Saudi Arabia 🇺🇸 USA 🇬🇧 UK 🇨🇦 Canada 🇦🇺 Australia 🇩🇪 Germany 🇫🇷 France 🇹🇷 Turkey 🇲🇾 Malaysia 🇮🇩 Indonesia 🇧🇩 Bangladesh 🇱🇰 Sri Lanka 🇳🇵 Nepal 🇧🇹 Bhutan 🇲🇻 Maldives 🇦🇫 Afghanistan 🇮🇷 Iran 🇧🇭 Bahrain 🇶🇦 Qatar 🇴🇲 Oman 🇰🇼 Kuwait 🇪🇬 Egypt

### 👨‍💼 For Administrators

#### 🔐 Admin Login
1. Visit `http://localhost:3000/admin/sign_in`
2. Use credentials: `admin@example.com` / `password123`

#### 📊 Dashboard Overview
- **Real-time Metrics**: Current order counts, available Qurans, stock levels
- **Interactive Charts**: View order trends by day, week, month, or year
- **Recent Orders**: Latest customer orders with basic details
- **Stock Alerts**: Automatic notifications for Qurans with low inventory

#### 🛒 Order Management
**Access**: Sidebar → "Order Management" link

##### Order Overview
- **Status Counters**: Live counts of Pending, Processing, Shipped, and Delivered orders
- **Filter System**: Filter by status and date ranges with AJAX (no page reload!)
- **CSV Export**: Export order data for external analysis

##### Managing Orders
1. **View Order List**: See all customer orders with details
2. **Filter Orders**: Use AJAX filters to find specific orders instantly
3. **Update Status**:
   - **Dropdown Update**: Change status from table dropdown (immediate AJAX save)
   - **Quick Actions**: Use buttons for Processing/Shipped/Delivered status
   - **Individual View**: Click "View" for complete order details

##### Order Status Workflow
```
Pending → Processing → Shipped → Delivered
    ↓        ↓        ↓        ↓
   New →   Handling →Shipping→Complete
```

#### 📚 Quran Management
**Access**: Sidebar → "Quran Management"

- **Add New Qurans**: Upload books with title, author, pages, translation
- **Edit Existing Books**: Modify book information and stock levels
- **Image Management**: Upload and manage Quran cover images
- **Stock Control**: Track and update inventory levels
- **Delete Books**: Remove inactive titles

#### 📈 Analytics & Reporting
**Access**: Sidebar → "Analytics" section

- **Order Analytics**: View order trends with interactive charts
- **Customer Insights**: Customer demographics and preferences
- **Geographic Data**: Worldwide order distribution heatmap
- **Monthly Reports**: CSV exportable reports
- **Stock Reports**: Inventory levels by translation type

## 🔄 Complete Workflow

```
🌍 GLOBAL USER JOURNEY:
User from Pakistan → Visits site → Selects Pakistan → Lahore loads →
Fills Urdu contact info → AJAX submit → Success confirmation

👨‍💼 ADMIN WORKFLOW:
Login → Order Management → See pending orders (count: 5) →
Filter by Pakistan only → View individual order details →
Use Quick Actions → Mark as Processing (count updates to 4 Processing) →
Later mark as Shipped → Finally Delivered ✅
```

## 🧪 Testing

### Run Test Suite
```bash
rails test        # Run all tests
rails test:controllers  # Run controller tests
rails test:models       # Run model tests
```

### Sample Test Data
```bash
rails db:seed    # Creates sample orders, Qurans, and admin user
```

## 🚀 Deployment

### Production Deployment (Recommended: Heroku/Vercel + AWS RDS)

1. **Environment Variables**
```bash
DATABASE_URL=postgresql://...
REDIS_URL=redis://... (optional)
SECRET_KEY_BASE=your-secret-key
RAILS_MASTER_KEY=your-master-key
```

2. **Database Migration**
```bash
rails db:migrate
```

3. **Asset Compilation**
```bash
rails assets:precompile
```

## 🤝 Contributing

### Development Guidelines
- Follow Rails best practices
- Use proper tests for new features
- Maintain international accessibility
- Keep Islamic content respectful and authentic

### Adding New Countries
1. Add country to `OrdersController#load_countries_data`
2. Add phone formats to `OrdersController#load_phone_formats`
3. Test with real users from that country

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- **Allah (SWT)** for the blessing of the Holy Quran
- **Rasulullah (SAW)** for guiding humanity to the straight path
- **Islamic Ummah** for supporting Quranic education worldwide

---

**Made with ❤️ for Islamic service worldwide**

May Allah accept this work and multiply the reward for everyone involved in spreading Quranic knowledge.

*إِنَّ اللّٰهَ وَمَلٰٓئِكَتَهٗ يُصَلُّوْنَ عَلَى النَّبِيِّ ۗ يٰٓاَيُّهَا الَّذِيْنَ اٰمَنُوْا صَلُّوْا عَلَيْهِ وَسَلِّمُوْا تَسْلِيْمًا* 

**آمين** 🤲🕌

---

For questions or support: contact@freequrandistribution.org
