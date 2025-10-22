// Floating Action Button (FAB) Functionality
let isFabMenuOpen = false;

document.addEventListener('DOMContentLoaded', function() {
  try {
    console.log('🔄 FAB Debug: DOMContentLoaded triggered, initializing FAB...');

    const fabMainBtn = document.getElementById('fab-main-btn');
    const fabIcon = document.getElementById('fab-icon');
    const fabMenu = document.getElementById('fab-menu');

    console.log('🔍 FAB Debug: FAB elements found:', {
      fabMainBtn: !!fabMainBtn,
      fabIcon: !!fabIcon,
      fabMenu: !!fabMenu
    });

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
