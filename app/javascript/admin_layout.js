// Floating Action Button (FAB) Functionality
let isFabMenuOpen = false;

// BASIC SYNTAX CHECK - if you see this, file is loading
try {
  console.log('🧪🚨 ADMIN_LAYOUT.JS BASIC SYNTAX TEST - FILE LOADED OK!');
  console.log('📍 Current timestamp:', new Date().toISOString());
  console.log('🔍 Location:', window.location.href);
} catch(e) {
  console.error('❌ SYNTAX ERROR:', e);
}

// Dashboard test log - should appear on every admin page load
console.log('🧪 admin_layout.js LOADED successfully!');

document.addEventListener('DOMContentLoaded', function() {
  try {
    console.log('🚀 FAB Debug: Initializing FAB...');

    const fabMainBtn = document.getElementById('fab-main-btn');
    const fabIcon = document.getElementById('fab-icon');
    const fabMenu = document.getElementById('fab-menu');

    // Make sure elements exist
    if (fabMainBtn && fabIcon && fabMenu) {
      console.log('✅ FAB Debug: All FAB elements found, attaching event listeners...');

      // Toggle menu on FAB click
      fabMainBtn.addEventListener('click', function() {
        console.log('🚀 FAB Debug: FAB main button clicked!');
        toggleFab();
      });

      // Close menu when clicking outside
      document.addEventListener('click', function(event) {
        if (!fabMainBtn.contains(event.target) && !fabMenu.contains(event.target) && isFabMenuOpen) {
          console.log('🚪 FAB Debug: Clicking outside, closing menu...');
          closeFab();
        }
      });

      console.log('🎯 FAB Debug: Event listeners attached successfully!');
    } else {
      console.error('❌ FAB Error: One or more FAB elements not found:', {
        fabMainBtn: !!fabMainBtn,
        fabIcon: !!fabIcon,
        fabMenu: !!fabMenu
      });
    }
  } catch (error) {
    console.error('❌ FAB Error: DOMContentLoaded initialization failed:', error);
  }

  // Initialize dark mode from localStorage
  const darkModeEnabled = localStorage.getItem('adminDarkMode') === 'true';
  if (darkModeEnabled) {
    document.documentElement.classList.add('dark');
    document.getElementById('dark-mode-icon').className = 'fas fa-sun text-base';
  }

  // Initialize sidebar state from localStorage
  const sidebarHidden = localStorage.getItem('adminSidebarHidden') === 'true';
  const sidebarIcon = document.getElementById('sidebar-icon');

  if (sidebarHidden) {
    document.body.classList.add('sidebar-hidden');
    sidebarIcon.className = 'fas fa-angle-right text-base'; // Arrow pointing right when sidebar is hidden
  }

  // Close sidebar options when clicking outside (removed duplicate at bottom)
});

// Immediate theme loading to prevent flicker
(function() {
  try {
    console.log('🚀 FAB Debug: Initializing admin_layout.js...');

    // Load saved theme immediately to prevent flicker
    const savedTheme = localStorage.getItem('adminTheme') || 'green';
    console.log('🎨 FAB Debug: Loaded theme:', savedTheme);

    if (savedTheme !== 'green') {
      document.body.classList.add(`theme-${savedTheme}`);
      console.log('✅ FAB Debug: Applied theme class:', `theme-${savedTheme}`);
    }

    // Load user's sidebar state
    const sidebarHidden = localStorage.getItem('adminSidebarHidden') === 'true';
    if (sidebarHidden) {
      document.body.classList.add('sidebar-hidden');
      console.log('✅ FAB Debug: Sidebar hidden state applied');
    }

    // Load user's sidebar mode
    const sidebarMode = localStorage.getItem('sidebarMode');
    if (sidebarMode && sidebarMode !== 'normal') {
      const sidebarEl = document.querySelector('body aside');
      if (sidebarEl) {
        if (sidebarMode === 'locked') {
          sidebarEl.classList.add('sidebar-locked');
          console.log('✅ FAB Debug: Sidebar locked mode applied');
        } else if (sidebarMode === 'scrolled') {
          sidebarEl.classList.add('sidebar-scrolled');
          console.log('✅ FAB Debug: Sidebar scrolled mode applied');
        }
      }
    }
    console.log('🌟 FAB Debug: Initialization complete!');
  } catch (error) {
    console.error('❌ FAB Error: Initialization failed:', error);
  }
})();

// 0. Sidebar Toggle
function fabToggleSidebar() {
  const body = document.body;
  const sidebarIcon = document.getElementById('sidebar-icon');
  const isHidden = body.classList.toggle('sidebar-hidden');

  if (isHidden) {
    // Sidebar is now hidden
    sidebarIcon.className = 'fas fa-angle-right text-base'; // Right arrow to show it
    localStorage.setItem('adminSidebarHidden', 'true');
    showFabFeedback('Sidebar hidden!', 'light');
  } else {
    // Sidebar is now visible
    sidebarIcon.className = 'fas fa-bars text-base'; // Bars icon to hide it
    localStorage.setItem('adminSidebarHidden', 'false');
    showFabFeedback('Sidebar shown!', 'success');
  }
}

// 1. Print Page
function fabPrintPage() {
  window.print();
}

// 2. Full Screen Toggle
function fabToggleFullscreen() {
  if (!document.fullscreenElement) {
    document.documentElement.requestFullscreen().catch(err => {
      console.error('Error attempting to enable full-screen mode:', err.message);
    });
  } else {
    if (document.exitFullscreen) {
      document.exitFullscreen();
    }
  }
}

// 3. Logout
function fabLogout() {
  if (confirm('Are you sure you want to logout?')) {
    try {
      console.log('🚪 FAB Debug: Starting logout process...');

      // Create and submit a form to the logout endpoint
      const form = document.createElement('form');
      form.method = 'POST';
      form.action = '<%= destroy_admin_session_path %>';

      // Add CSRF token
      const csrfToken = document.querySelector('[name="authenticity_token"]');
      if (csrfToken) {
        const hiddenInput = document.createElement('input');
        hiddenInput.type = 'hidden';
        hiddenInput.name = 'authenticity_token';
        hiddenInput.value = csrfToken.value;
        form.appendChild(hiddenInput);
        console.log('✅ FAB Debug: CSRF token added');
      } else {
        console.warn('⚠️ FAB Warn: No CSRF token found');
      }

      // Add _method for DELETE
      const methodInput = document.createElement('input');
      methodInput.type = 'hidden';
      methodInput.name = '_method';
      methodInput.value = 'delete';
      form.appendChild(methodInput);

      document.body.appendChild(form);
      console.log('✅ FAB Debug: Logout form submitted');
      form.submit();
    } catch (error) {
      console.error('❌ FAB Error: fabLogout() failed:', error);
    }
  }
}

// 4. Scroll Up
function fabScrollToTop() {
  window.scrollTo({
    top: 0,
    behavior: 'smooth'
  });
}

// 5. Dark Theme Toggle
function fabToggleDarkMode() {
  const darkModeIcon = document.getElementById('dark-mode-icon');
  const isDarkMode = document.documentElement.classList.toggle('dark');

  if (isDarkMode) {
    // Switch to sun icon (indicating it will switch to light mode)
    darkModeIcon.className = 'fas fa-sun text-base';
    localStorage.setItem('adminDarkMode', 'true');
  } else {
    // Switch to moon icon (indicating it will switch to dark mode)
    darkModeIcon.className = 'fas fa-moon text-base';
    localStorage.setItem('adminDarkMode', 'false');
  }

  // Show visual feedback
  showFabFeedback('Theme switched!', isDarkMode ? 'dark' : 'light');
}

// FAB Menu Toggle Functions
function toggleFab() {
  try {
    console.log('🔄 FAB Debug: toggleFab() called, current state:', isFabMenuOpen);

    const fabIcon = document.getElementById('fab-icon');
    const fabMenu = document.getElementById('fab-menu');

    console.log('🔍 FAB Debug: toggleFab() elements found:', {
      fabIcon: !!fabIcon,
      fabMenu: !!fabMenu
    });

    if (fabIcon && fabMenu) {
      isFabMenuOpen = !isFabMenuOpen;
      console.log('🔄 FAB Debug: Menu state changed to:', isFabMenuOpen);

      if (isFabMenuOpen) {
        console.log('📍 FAB Debug: Opening menu...');
        fabIcon.classList.add('rotate-45');
        fabMenu.classList.remove('opacity-0', 'pointer-events-none', 'translate-y-4');
        fabMenu.classList.add('opacity-100', 'pointer-events-auto', 'translate-y-0');
        console.log('✅ FAB Debug: Menu opened successfully');
      } else {
        console.log('📍 FAB Debug: Closing menu...');
        closeFab();
      }
    } else {
      console.error('❌ FAB Error: toggleFab() - Elements not found!');
    }
  } catch (error) {
    console.error('❌ FAB Error: toggleFab() failed:', error);
  }
}

function closeFab() {
  try {
    console.log('📍 FAB Debug: closeFab() called');

    const fabIcon = document.getElementById('fab-icon');
    const fabMenu = document.getElementById('fab-menu');

    if (fabIcon && fabMenu) {
      fabIcon.classList.remove('rotate-45');
      fabMenu.classList.remove('opacity-100', 'pointer-events-auto', 'translate-y-0');
      fabMenu.classList.add('opacity-0', 'pointer-events-none', 'translate-y-4');
      isFabMenuOpen = false;
      console.log('✅ FAB Debug: Menu closed successfully');
    } else {
      console.error('❌ FAB Error: closeFab() - Elements not found!');
    }
  } catch (error) {
    console.error('❌ FAB Error: closeFab() failed:', error);
  }
}

// Sidebar Options Functions
function showSidebarOptions(event) {
  event.preventDefault();
  event.stopPropagation();
  const optionsMenu = document.getElementById('sidebar-options');
  optionsMenu.classList.toggle('show');
}

function toggleSidebarLock() {
  const body = document.body;
  const sidebar = body.querySelector('aside');

  // Remove previous sidebar states
  body.classList.remove('sidebar-hidden');
  sidebar.classList.remove('sidebar-locked');
  sidebar.classList.remove('sidebar-scrolled');

  // Apply locked state
  sidebar.classList.add('sidebar-locked');
  body.classList.remove('sidebar-hidden'); // Ensure sidebar is visible

  // Close options menu
  document.getElementById('sidebar-options').classList.remove('show');

  // Save preference
  localStorage.setItem('sidebarMode', 'locked');

  showFabFeedback('Sidebar locked!', 'success');
  localStorage.setItem('adminSidebarHidden', 'false');
}

function unlockSidebar() {
  const body = document.body;
  const sidebar = body.querySelector('aside');

  // Remove previous sidebar states
  body.classList.remove('sidebar-hidden');
  sidebar.classList.remove('sidebar-locked');
  sidebar.classList.remove('sidebar-scrolled');

  // Apply scrolled state
  sidebar.classList.add('sidebar-scrolled');

  // Close options menu
  document.getElementById('sidebar-options').classList.remove('show');

  // Add scroll event listener for parallax effect
  window.addEventListener('scroll', handleSidebarScroll);

  // Save preference
  localStorage.setItem('sidebarMode', 'scrolled');

  showFabFeedback('Sidebar unlocked - auto scroll enabled!', 'success');
  localStorage.setItem('adminSidebarHidden', 'false');
}

function hideSidebar() {
  const body = document.body;
  const sidebar = body.querySelector('aside');

  // Remove all sidebar states and hide it
  sidebar.classList.remove('sidebar-locked', 'sidebar-scrolled');
  body.classList.add('sidebar-hidden');

  // Close options menu
  document.getElementById('sidebar-options').classList.remove('show');

  // Update icon
  const sidebarIcon = document.getElementById('sidebar-icon');
  sidebarIcon.className = 'fas fa-angle-right text-base';

  // Save preferences
  localStorage.setItem('sidebarMode', 'hidden');
  localStorage.setItem('adminSidebarHidden', 'true');

  showFabFeedback('Sidebar hidden!', 'light');
}

function showSidebar() {
  const body = document.body;
  const sidebarIcon = document.getElementById('sidebar-icon');

  // Show sidebar by removing hidden class
  body.classList.remove('sidebar-hidden');
  sidebarIcon.className = 'fas fa-bars text-base'; // Bars icon

  // Reset to default mode if it was hidden
  localStorage.setItem('adminSidebarHidden', 'false');
  localStorage.setItem('sidebarMode', 'normal');

  showFabFeedback('Sidebar shown!', 'success');
}

function handleSidebarScroll() {
  const scrolled = window.pageYOffset;
  const rate = scrolled * -0.5; // Parallax effect

  const sidebar = document.querySelector('.sidebar-scrolled aside');
  if (sidebar) {
    sidebar.style.transform = `translateY(${rate}px)`;
  }

  // Hide sidebar when scrolled too far down on mobile
  if (window.innerWidth < 768 && scrolled > 200) {
    document.body.classList.add('sidebar-hidden');
  }
}

// Initialize sidebar mode on page load
document.addEventListener('DOMContentLoaded', function() {
  const sidebarMode = localStorage.getItem('sidebarMode') || 'normal';
  const body = document.body;
  const sidebar = body.querySelector('aside');

  switch (sidebarMode) {
    case 'locked':
      sidebar.classList.add('sidebar-locked');
      break;
    case 'scrolled':
      sidebar.classList.add('sidebar-scrolled');
      window.addEventListener('scroll', handleSidebarScroll);
      break;
    case 'hidden':
      body.classList.add('sidebar-hidden');
      break;
    default:
      // Normal behavior
      break;
  }
});



// Helper function for visual feedback
function showFabFeedback(message, type) {
  // Create notification element
  const notification = document.createElement('div');
  notification.className = 'fixed top-4 right-4 z-50 px-4 py-2 rounded-lg shadow-lg transition-all duration-300 transform translate-x-full';
  notification.textContent = message;

  // Style based on type
  const colorClasses = type === 'success' ? 'bg-green-500 text-white' :
                       type === 'dark' ? 'bg-purple-500 text-white' :
                       type === 'light' ? 'bg-blue-500 text-white' : 'bg-gray-500 text-white';

  notification.className += ` ${colorClasses}`;

  // Add to page
  document.body.appendChild(notification);

  // Animate in
  setTimeout(() => {
    notification.classList.remove('translate-x-full');
  }, 100);

  // Remove after 3 seconds
  setTimeout(() => {
    notification.classList.add('translate-x-full');
    setTimeout(() => {
      notification.remove();
    }, 300);
  }, 3000);
}

// Dashboard AJAX and Animation Functions
// Global variable to store current selected period
let currentDashboardPeriod = 'month'; // Default matches controller default

// Counter animation function for smooth number increments
function animateCounter(element, startValue, endValue, duration = 1000) {
  if (startValue === endValue) return;

  const startTime = performance.now();
  const difference = endValue - startValue;

  function updateCounter(currentTime) {
    const elapsed = currentTime - startTime;
    const progress = Math.min(elapsed / duration, 1);

    // Easing function for smoother animation
    const easeOutQuart = 1 - Math.pow(1 - progress, 4);
    const currentValue = Math.round(startValue + (difference * easeOutQuart));

    element.textContent = currentValue.toLocaleString();

    if (progress < 1) {
      requestAnimationFrame(updateCounter);
    }
  }

  requestAnimationFrame(updateCounter);
}

// Function to update chart period and data
function updateChartPeriod(period) {
  console.log('🔄 Updating chart to period:', period);
  currentDashboardPeriod = period;

  // Update the page title to reflect current period
  const titleElement = document.querySelector('#ordersChart + div h3');
  if (titleElement) {
    titleElement.textContent = `${period.charAt(0).toUpperCase() + period.slice(1)} Orders Trend`;
  }

  // Refresh dashboard to get new chart data
  refreshDashboard();

  // Also trigger immediate refresh to update charts
  setTimeout(() => {
    if (typeof refreshDashboard === 'function') {
      refreshDashboard();
    }
  }, 100);
}

// Function to update stats with counter animations
function updateStats(stats) {
  console.log('📊 Updating dashboard stats:', stats);

  // Update each counter with animation if possible
  const statMappings = [
    ['#stats_total_orders', stats.total_orders],
    ['#stats_countries_served', stats.countries_served],
    ['#stats_qurans_distributed', stats.qurans_distributed],
    ['#stats_stock_remaining', stats.stock_remaining]
  ];

  statMappings.forEach(([selector, newValue]) => {
    const element = document.querySelector(selector);
    if (element) {
      console.log(`🎯 Found element ${selector}, animating to ${newValue}`);
      const currentValue = parseInt(element.textContent.replace(/,/g, '')) || 0;
      animateCounter(element, currentValue, newValue, 1000);
    } else {
      console.warn(`❌ Element ${selector} not found in DOM!`);
      // Fallback: just set the value directly without animation
      console.log(`🔄 Direct update for ${selector}: ${newValue}`);
    }
  });

  // DEBUG: List all elements matching our patterns
  console.log('🔍 DEBUG: Available elements in DOM:');
  console.log('  #stats_total_orders:', document.querySelector('#stats_total_orders'));
  console.log('  #stats_countries_served:', document.querySelector('#stats_countries_served'));
  console.log('  #stats_qurans_distributed:', document.querySelector('#stats_qurans_distributed'));
  console.log('  #stats_stock_remaining:', document.querySelector('#stats_stock_remaining'));
  console.log('  Total h3 elements:', document.querySelectorAll('h3').length);
  console.log('  Stats h3 elements:', document.querySelectorAll('h3[id*="stats"]').length);
}

// Function to update charts
function updateCharts(data) {
  console.log('📈 Updating charts with data:', data);
  // Update orders chart if data exists
  if (data.charts && data.charts.labels && data.charts.data) {
    if (window.ordersChart) {
      window.ordersChart.data.labels = data.charts.labels;
      window.ordersChart.data.datasets[0].data = data.charts.data;
      window.ordersChart.update('none'); // 'none' prevents animation conflicts
      console.log('✅ Orders chart updated');
    } else {
      console.warn('⚠️ Orders chart not found');
    }
  }

  // Update stock chart if data exists
  if (data.stock_data) {
    if (window.stockChart) {
      window.stockChart.data.labels = Object.keys(data.stock_data);
      window.stockChart.data.datasets[0].data = Object.values(data.stock_data);
      window.stockChart.update('none');
      console.log('✅ Stock chart updated');
    } else {
      console.warn('⚠️ Stock chart not found');
    }
  }
}

// Main refresh function that replaces the full page reload
async function refreshDashboard() {
  try {
    console.log('🔄 Starting dashboard refresh...');

    // Include current selected period in the request
    const url = `/admin/dashboard/live_stats.json?period=${encodeURIComponent(currentDashboardPeriod)}`;
    console.log('📊 Refreshing with period:', currentDashboardPeriod);

    const response = await fetch(url, {
      method: 'GET',
      headers: {
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]')?.getAttribute('content') || ''
      }
    });

    if (!response.ok) {
      console.warn('❌ Failed to fetch live stats:', response.status);
      return;
    }

    const data = await response.json();
    console.log('📋 Received live stats for period', currentDashboardPeriod, ':', data);

    // Update different sections with animations
    if (data.stats) updateStats(data.stats);
    if (data.charts) updateCharts(data);

    console.log('✅ Dashboard refresh completed');

  } catch (error) {
    console.error('❌ Dashboard refresh failed:', error);
  }
}

// Initialize dashboard functionality for admin pages
function initializeDashboard() {
  console.log('📌 initializeDashboard() function called!');
  // Only run on dashboard pages
  const hasDashboardElements = document.querySelector('#stats_countries_served') ||
                              document.querySelector('#stats_total_orders') ||
                              document.querySelector('#ordersChart') ||
                              document.querySelector('#stockChart');

  if (!hasDashboardElements) {
    console.log('📊 Not a dashboard page, skipping dashboard init');
    return;
  }

  console.log('🚀 Initializing dashboard functionality');

  // Extract period from URL params if present
  const urlParams = new URLSearchParams(window.location.search);
  const urlPeriod = urlParams.get('period');
  if (urlPeriod && ['day', 'week', 'month', 'year'].includes(urlPeriod)) {
    currentDashboardPeriod = urlPeriod;
    console.log('📅 Set dashboard period from URL:', currentDashboardPeriod);
  } else {
    console.log('📅 Using default dashboard period:', currentDashboardPeriod);
  }

  // Get refresh interval from meta tag (set by Rails)
  const refreshInterval = parseInt(document.querySelector('meta[name="dashboard-refresh-interval"]')?.getAttribute('content')) || 30;
  console.log(`⏱️ Dashboard refresh interval: ${refreshInterval} seconds`);

  // Initialize charts if they exist
  initializeCharts();

  // Start AJAX refresh
  if (refreshInterval > 0 && refreshInterval < 60) {
    console.log('🕒 Starting interval refresh...');
    setInterval(refreshDashboard, refreshInterval * 1000);
    console.log(`✅ Dashboard will refresh every ${refreshInterval} seconds`);
  } else {
    console.log('⏸️ Refresh interval disabled or too long (max 60s)');
  }
}

// Initialize Chart.js charts for dashboard
function initializeCharts() {
  // Destroy existing charts to prevent canvas reuse error
  if (window.ordersChart && typeof window.ordersChart.destroy === 'function') {
    window.ordersChart.destroy();
  }
  if (window.stockChart && typeof window.stockChart.destroy === 'function') {
    window.stockChart.destroy();
  }

  // Orders Chart
  const ordersCtx = document.getElementById("ordersChart");
  if (ordersCtx && typeof Chart !== 'undefined') {
    console.log('📈 Initializing orders chart');
    window.ordersChart = new Chart(ordersCtx, {
      type: "line",
      data: {
        labels: window.dashboardLabels || [],
        datasets: [{
          label: "Orders",
          data: window.dashboardOrdersData || [],
          borderColor: "#16a34a",
          backgroundColor: "rgba(22,163,74,0.1)",
          fill: true,
          tension: 0.4,
          pointRadius: 5
        }]
      },
      options: { responsive: true, scales: { y: { beginAtZero: true } } }
    });
  }

  // Stock Chart
  const stockCtx = document.getElementById("stockChart");
  if (stockCtx && typeof Chart !== 'undefined') {
    console.log('📊 Initializing stock chart');
    window.stockChart = new Chart(stockCtx, {
      type: "bar",
      data: {
        labels: window.dashboardStockLabels || [],
        datasets: [{
          label: "Stock Remaining",
          data: window.dashboardStockData || [],
          backgroundColor: "#16a34a"
        }]
      },
      options: { responsive: true, scales: { y: { beginAtZero: true } } }
    });
  }
}

// Initialize when DOM is ready or when Turbo loads a new page
document.addEventListener('DOMContentLoaded', initializeDashboard);
// Turbo events for single-page app navigation
document.addEventListener('turbo:load', initializeDashboard);
document.addEventListener('turbo:frame-load', initializeDashboard);

// Global functions for header inline scripts
window.setTheme = function(theme) {
  console.log('🎨 Setting theme to:', theme);

  // Remove all theme classes first
  const themeClasses = ['theme-green', 'theme-purple', 'theme-black', 'theme-sky'];
  themeClasses.forEach(className => {
    document.body.classList.remove(className);
  });

  // Apply the new theme if not green (default)
  if (theme !== 'green') {
    document.body.classList.add(`theme-${theme}`);
  }

  // Save to localStorage
  localStorage.setItem('adminTheme', theme);

  // Show feedback
  if (typeof showFabFeedback === 'function') {
    showFabFeedback(`Theme switched to ${theme}!`, 'success');
  }

  console.log('✅ Theme set successfully');
};

// Helper function for visual feedback
function showFabFeedback(message, type) {
  // Create notification element
  const notification = document.createElement('div');
  notification.className = 'fixed top-4 right-4 z-50 px-4 py-2 rounded-lg shadow-lg transition-all duration-300 transform translate-x-full';
  notification.textContent = message;

  // Style based on type
  const colorClasses = type === 'success' ? 'bg-green-500 text-white' :
                       type === 'dark' ? 'bg-purple-500 text-white' :
                       type === 'light' ? 'bg-blue-500 text-white' : 'bg-gray-500 text-white';

  notification.className += ` ${colorClasses}`;

  // Add to page
  document.body.appendChild(notification);

  // Animate in
  setTimeout(() => {
    notification.classList.remove('translate-x-full');
  }, 100);

  // Remove after 3 seconds
  setTimeout(() => {
    notification.classList.add('translate-x-full');
    setTimeout(() => {
      notification.remove();
    }, 300);
  }, 3000);
}

// Make functions globally available
window.initializeDashboard = initializeDashboard;
window.setTheme = setTheme;
window.showFabFeedback = showFabFeedback;

// Manual test - run on immediately
console.log('🧪 Trying manual dashboard init...');
setTimeout(() => {
  console.log('⏳ Running with timeout...');
  initializeDashboard();
}, 100);

// EMERGENCY TEST - Force run refresh after 2 seconds
setTimeout(() => {
  console.log('🚨 EMERGENCY TEST: Force calling refreshDashboard()');
  if (typeof refreshDashboard === 'function') {
    refreshDashboard();
  } else {
    console.error('❌ refreshDashboard function not found!');
  }
}, 2000);
