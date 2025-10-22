require 'rails_helper'

RSpec.describe 'layouts/_header.html.erb', type: :view do
  before(:each) do
    # Mock request environment for Devise
    allow(view).to receive(:current_admin).and_return(double(
      first_name: 'Test',
      last_name: 'Admin',
      role: 'super_admin',
      full_name: 'Test Admin'
    ))

    allow(view).to receive(:admin_configuration_path).and_return('/admin/configuration')
    allow(view).to receive(:admin_notifications_path).and_return('/admin/notifications')
    allow(view).to receive(:destroy_admin_session_path).and_return('/admins/sign_out')
  end

  describe 'header rendering' do
    it 'renders the basic header structure' do
      render

      expect(rendered).to have_css('header.bg-white')
      expect(rendered).to have_css('div.flex.items-center.justify-between.px-6.py-3')
    end

    it 'renders the sidebar toggle button' do
      render

      expect(rendered).to have_css('button[onclick*="headerToggleSidebar"]')
      expect(rendered).to have_css('i.fas.fa-bars')
      expect(rendered).to have_css('div[id="sidebar-options"]')
    end

    it 'renders the sidebar options menu' do
      render

      within('div[id="sidebar-options"]') do
        expect(rendered).to have_button('Lock Sidebar')
        expect(rendered).to have_button('Auto Scroll')
        expect(rendered).to have_button('Hide Sidebar')
      end
    end

    it 'renders the admin panel title' do
      render

      expect(rendered).to have_css('h2', text: 'Quran Admin Panel')
    end

    it 'renders user interface elements' do
      render

      expect(rendered).to have_css('button[id="user-menu-btn"]')
      expect(rendered).to have_css('button[id="notification-btn"]')
      expect(rendered).to have_css('button[id="settings-btn"]')
    end

    it 'renders the notifications section' do
      render

      expect(rendered).to have_css('button[id="notification-btn"] i.fas.fa-bell')
      expect(rendered).to have_css('span[id="notification-badge"]')

      within('div[id="notification-menu"]') do
        expect(rendered).to have_css('h3', text: 'Notifications')
        expect(rendered).to have_content('Welcome to the Admin Panel')
        expect(rendered).to have_content('View all notifications →')
      end
    end

    it 'renders the settings section with enhanced UI' do
      render

      expect(rendered).to have_css('button[id="settings-btn"] i.fas.fa-cog')

      within('div[id="settings-menu"]') do
        expect(rendered).to have_css('p', text: 'Settings')

        # Check App Layout section with toggle switches
        expect(rendered).to have_css('p', text: 'APP LAYOUT')
        expect(rendered).to have_content('Fixed Header')
        expect(rendered).to have_content('Fixed Navigation')
        expect(rendered).to have_content('Boxed Layout')

        # Verify toggle switches are present
        expect(rendered).to have_css('input[type="checkbox"][id="fixed-header-toggle"]')
        expect(rendered).to have_css('input[type="checkbox"][id="fixed-navigation-toggle"]')
        expect(rendered).to have_css('input[type="checkbox"][id="boxed-layout-toggle"]')

        # Check Accessibility section with font size buttons and toggle switches
        expect(rendered).to have_css('p', text: 'ACCESSIBILITY')
        expect(rendered).to have_content('Content Font Size')
        expect(rendered).to have_content('High Contrast Text')
        expect(rendered).to have_content('Preloader Inside')

        # Verify font size buttons
        expect(rendered).to have_css('button[id="content-font-sm"]', text: 'SM')
        expect(rendered).to have_css('button[id="content-font-md"]', text: 'MD')
        expect(rendered).to have_css('button[id="content-font-lg"]', text: 'LG')
        expect(rendered).to have_css('button[id="content-font-xl"]', text: 'XL')

        # Verify accessibility toggles (without the bigger-font-toggle)
        expect(rendered).to have_css('input[type="checkbox"][id="high-contrast-toggle"]')
        expect(rendered).to have_css('input[type="checkbox"][id="preloader-toggle"]')

        # Check Reset button
        expect(rendered).to have_css('button[onclick*="resetAllSettingsToDefaults()"]')
        expect(rendered).to have_content('Reset All to Defaults')
      end
    end

    it 'renders Font Size button grid properly' do
      render

      within('div[id="settings-menu"]') do
        # Check font size buttons exist
        expect(rendered).to have_css('button[id="content-font-sm"]', text: 'SM')
        expect(rendered).to have_css('button[id="content-font-md"]', text: 'MD')
        expect(rendered).to have_css('button[id="content-font-lg"]', text: 'LG')
        expect(rendered).to have_css('button[id="content-font-xl"]', text: 'XL')

        # Check they are in a grid layout
        expect(rendered).to have_css('div.grid.grid-cols-4.gap-1')
      end
    end

    it 'renders future theme color swatches properly' do
      render

      within('div[id="settings-menu"]') do
        # Check all four theme buttons exist as color swatches
        expect(rendered).to have_css('button[id="theme-green"]')
        expect(rendered).to have_css('button[id="theme-sky"]')
        expect(rendered).to have_css('button[id="theme-black"]')
        expect(rendered).to have_css('button[id="theme-purple"]')

        # Check color swatch styling (rounded buttons instead of bars)
        expect(rendered).to have_css('.w-12.h-12.rounded-full', count: 4) # All theme buttons
        expect(rendered).to have_css('.bg-gradient-to-br.from-green-400.via-green-500.to-green-600')
        expect(rendered).to have_css('.bg-gradient-to-br.from-sky-400.via-sky-500.to-cyan-600')
        expect(rendered).to have_css('.bg-gradient-to-br.from-gray-700.via-gray-800.to-gray-900')
        expect(rendered).to have_css('.bg-gradient-to-br.from-purple-500.via-purple-600.to-purple-700')

        # Check theme indicators (pulse dots)
        expect(rendered).to have_css('#green-indicator')
        expect(rendered).to have_css('#sky-indicator')
        expect(rendered).to have_css('#black-indicator')
        expect(rendered).to have_css('#purple-indicator')

        # Check tooltip titles for accessibility
        expect(rendered).to have_css('button[title="Green Theme"]')
        expect(rendered).to have_css('button[title="Sky Blue Theme"]')
        expect(rendered).to have_css('button[title="Black Theme"]')
        expect(rendered).to have_css('button[title="Purple Theme"]')
      end
    end

    it 'renders reset button with proper styling' do
      render

      within('div[id="settings-menu"]') do
        expect(rendered).to have_css('button.bg-red-500.hover\\:bg-red-600.text-white.rounded-lg', text: 'Reset All to Defaults')
        expect(rendered).to have_css('button i.fas.fa-undo')
      end
    end

    it 'includes reset settings JavaScript function' do
      render

      expect(rendered).to include('function resetAllSettingsToDefaults()')
      expect(rendered).to include('confirm(\'Are you sure you want to reset all settings')
    end

    it 'renders toggle switches with proper structure' do
      render

      within('div[id="settings-menu"]') do
        # Check that all toggle switches have proper structure
        expect(rendered).to have_css('label.relative.inline-flex.items-center.cursor-pointer', count: 6)
        expect(rendered).to have_css('input.sr-only.peer[type="checkbox"]', count: 6)
        expect(rendered).to have_css('div.w-9.h-5.bg-red-400', count: 6) # Toggle switch backgrounds
      end
    end

    it 'includes all settings toggle JavaScript functions' do
      render

      # App Layout functions
      expect(rendered).to include('function toggleFixedHeader()')
      expect(rendered).to include('function toggleFixedNavigation()')
      expect(rendered).to include('function toggleBoxedLayout()')

      # Accessibility functions
      expect(rendered).to include('function setContentFontSize(size)')
      expect(rendered).to include('function toggleHighContrastText()')
      expect(rendered).to include('function togglePreloaderInside()')

      # Reset function
      expect(rendered).to include('function resetAllSettingsToDefaults()')
    end

    it 'includes proper ARIA labels and accessibility features' do
      render

      within('div[id="settings-menu"]') do
        # Screen reader only inputs
        expect(rendered).to have_css('input.sr-only', count: 6)
        # Proper toggle labels
        expect(rendered).to have_css('label.relative.inline-flex.items-center.cursor-pointer', count: 6)
      end
    end

    it 'includes proper CSS classes and structure' do
      render

      # Main header structure
      expect(rendered).to have_css('header > div[class*="flex items-center justify-between"]')
      expect(rendered).to have_css('div[class*="px-6 py-3"]')

      # Left section (toggle button and title)
      expect(rendered).to have_css('div[class*="flex items-center space-x-4"] button')
      expect(rendered).to have_css('div[class*="flex items-center space-x-4"] div[id="sidebar-options"]')
      expect(rendered).to have_css('div[class*="flex items-center space-x-4"] h2')

      # Right section (user info, notifications, settings)
      expect(rendered).to have_css('div[class*="flex items-center space-x-4"] .relative', minimum: 3)
      expect(rendered).to have_css('div.h-8.w-px') # Divider line
    end

    it 'includes JavaScript for interactivity' do
      render

      expect(rendered).to include('headerToggleSidebar')
      expect(rendered).to include('user-menu-btn')
      expect(rendered).to include('notification-btn')
      expect(rendered).to include('settings-btn')
      expect(rendered).to include('updateNotificationBadge')
    end

    it 'renders proper Rails route helpers' do
      render

      expect(rendered).to include('/admin/configuration')
      expect(rendered).to include('/admin/notifications')
      expect(rendered).to include('/admins/sign_out')
    end

    it 'includes responsive CSS classes' do
      render

      expect(rendered).to have_css('[class*="hidden md:block"]') # User info hidden on mobile
      expect(rendered).to have_css('[class*="justify-between"]')  # Flex justify between
      expect(rendered).to have_css('[class*="space-x-4"]')        # Spacing classes
    end

    it 'includes dark mode classes' do
      render

      expect(rendered).to have_css('[class*="dark:bg-gray-800"]')
      expect(rendered).to have_css('[class*="dark:text-gray-300"]')
      expect(rendered).to have_css('[class*="dark:border-gray-600"]')
    end
  end
end
