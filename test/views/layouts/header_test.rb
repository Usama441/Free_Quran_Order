require 'test_helper'

class HeaderTest < ActionView::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    # Create a mock warden proxy for Devise
    warden = Warden::Proxy.new({}, Warden::Manager.new(nil))
    @request.env['warden'] = warden

    # Mock current_admin method
    @controller = Admin::DashboardController.new
    @controller.request = @request

    @view.singleton_class.class_eval do
      define_method :current_admin do
        OpenStruct.new(
          first_name: 'Test',
          last_name: 'Admin',
          role: 'super_admin',
          full_name: 'Test Admin'
        )
      end

      define_method :admin_configuration_path do
        "/admin/configuration"
      end

      define_method :admin_notifications_path do
        "/admin/notifications"
      end

      define_method :destroy_admin_session_path do
        "/admins/sign_out"
      end
    end
  end

  test "renders header structure with proper styling" do
    render partial: 'layouts/header'

    assert_select 'header.bg-white' do
      assert_select 'div.flex.items-center.justify-between.px-6.py-3'
    end
  end

  test "renders sidebar toggle button correctly" do
    render partial: 'layouts/header'

    assert_select 'button[onclick*="showSidebarOptions"]'
    assert_select 'i.fas.fa-bars'
    assert_select 'div[id="sidebar-options"]'
  end

  test "renders basic sidebar options menu structure" do
    render partial: 'layouts/header'

    assert_select 'div[id="sidebar-options"]' do
      assert_select 'button', text: 'Lock Sidebar'
      assert_select 'button', text: 'Auto Scroll'
      assert_select 'button', text: 'Hide Sidebar'
    end
  end

  test "renders admin panel title correctly" do
    render partial: 'layouts/header'

    assert_select 'h2', text: 'Quran Admin Panel'
  end

  test "renders user interface elements" do
    render partial: 'layouts/header'

    assert_select 'button[id="user-menu-btn"]'
    assert_select 'button[id="notification-btn"]'
    assert_select 'button[id="settings-btn"]'
  end

  test "renders notifications section" do
    render partial: 'layouts/header'

    assert_select 'button[id="notification-btn"]' do
      assert_select 'i.fas.fa-bell'
      assert_select 'span[id="notification-badge"]'
    end

    assert_select 'div[id="notification-menu"]' do
      assert_select 'h3', text: 'Notifications'
      assert_select 'div', text: /Welcome to the Admin Panel/
      assert_select 'span', text: /View all notifications →/
    end
  end

  test "renders settings section" do
    render partial: 'layouts/header'

    assert_select 'button[id="settings-btn"]' do
      assert_select 'i.fas.fa-cog'
    end

    assert_select 'div[id="settings-menu"]' do
      assert_select 'p', text: 'Settings'
      assert_select 'button', text: 'Configuration'
      assert_select 'button', text: 'Notifications'
      assert_select 'button', text: 'Theme Settings'
    end
  end

  test "applies proper CSS classes and structure" do
    render partial: 'layouts/header'

    # Check main header structure
    assert_select 'header' do
      assert_select 'div[class*="flex items-center justify-between"]'
      assert_select 'div[class*="px-6 py-3"]'

      # Check left section has toggle button and title
      assert_select 'div[class*="flex items-center space-x-4"]' do
        assert_select 'button'
        assert_select 'div[id="sidebar-options"]'
        assert_select 'h2'
      end

      # Check right section
      assert_select 'div[class*="flex items-center space-x-4"]' do
        assert_select 'div[class*="relative"]', count: 3 # User info, notifications, settings
        assert_select 'div.h-8.w-px' # Divider line
      end
    end
  end

  test "includes JavaScript for interactivity" do
    render partial: 'layouts/header'

    assert_select 'script', count: 1
    rendered = rendered_to_string

    # Check that key JavaScript functions are present
    assert_includes rendered, 'showSidebarOptions'
    assert_includes rendered, 'user-menu-btn'
    assert_includes rendered, 'notification-btn'
    assert_includes rendered, 'settings-btn'
    assert_includes rendered, 'updateNotificationBadge'
  end

  test "renders proper link destinations" do
    render partial: 'layouts/header'

    rendered = render_to_string

    # Check that admin paths are used
    assert_includes rendered, admin_configuration_path
    assert_includes rendered, admin_notifications_path
    assert_includes rendered, destroy_admin_session_path
  end

  test "responsive classes are present" do
    render partial: 'layouts/header'

    assert_select 'div[class*="hidden md:block"]' # User info hidden on mobile
    assert_select 'div[class*="justify-between"]'  # Flex justify between
    assert_select 'div[class*="space-x-4"]'        # Spacing classes
  end

  test "dark mode classes are included" do
    render partial: 'layouts/header'

    assert_select '[class*="dark:bg-gray-800"]'
    assert_select '[class*="dark:text-gray-300"]'
    assert_select '[class*="dark:border-gray-600"]'
  end
end
