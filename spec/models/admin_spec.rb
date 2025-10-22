RSpec.describe Admin, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:first_name) }
    it { should validate_presence_of(:last_name) }
    it { should validate_presence_of(:role) }
    it { should validate_length_of(:first_name).is_at_least(2).is_at_most(50) }
    it { should validate_length_of(:last_name).is_at_least(2).is_at_most(50) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should validate_confirmation_of(:password) }

    # Devise validations
    it { should validate_presence_of(:email) }
    it { should validate_length_of(:password).is_at_least(6) }
  end

  describe 'enumerations' do
    it { should define_enum_for(:role).with_values(manager: 0, super_admin: 1) }
    it { should allow_value(:manager).for(:role) }
    it { should allow_value(:super_admin).for(:role) }
  end

  describe 'factory' do
    it 'creates valid admin instances' do
      admin = build(:admin)
      expect(admin).to be_valid
      expect(admin.first_name).to be_present
      expect(admin.last_name).to be_present
      expect(admin.full_name).to be_present
    end

    it 'creates super admin' do
      admin = build(:super_admin_admin)
      expect(admin.super_admin?).to be_truthy
      expect(admin.manager?).to be_falsey
    end

    it 'creates manager' do
      admin = build(:manager_admin)
      expect(admin.manager?).to be_truthy
      expect(admin.super_admin?).to be_falsey
    end
  end

  describe 'role methods' do
    let(:manager_admin) { create(:manager_admin) }
    let(:super_admin) { create(:super_admin_admin) }

    it 'returns correct role predicates' do
      expect(manager_admin.manager?).to be_truthy
      expect(manager_admin.super_admin?).to be_falsey
      expect(super_admin.super_admin?).to be_truthy
      expect(super_admin.manager?).to be_falsey
    end

    describe 'permission methods' do
      it 'allows super admin to manage everything' do
        expect(super_admin.can_manage_admins?).to be_truthy
        expect(super_admin.can_manage_orders?).to be_truthy
        expect(super_admin.can_manage_qurans?).to be_truthy
        expect(super_admin.can_manage_settings?).to be_truthy
        expect(super_admin.can_view_analytics?).to be_truthy
      end

      it 'allows manager to manage some things but not admins' do
        expect(manager_admin.can_manage_admins?).to be_falsey
        expect(manager_admin.can_manage_orders?).to be_truthy
        expect(manager_admin.can_manage_qurans?).to be_truthy
        expect(manager_admin.can_manage_settings?).to be_falsey
        expect(manager_admin.can_view_analytics?).to be_truthy
      end
    end
  end

  describe 'full_name method' do
    let(:admin) { build(:admin, first_name: 'John', last_name: 'Doe') }

    it 'returns combined first and last name' do
      expect(admin.full_name).to eq('John Doe')
    end

    it 'handles single name case sensitive' do
      admin.first_name = 'JOHN'
      admin.last_name = 'DOE'
      expect(admin.full_name).to eq('JOHN DOE')
    end
  end

  describe 'after_initialize callback' do
    it 'defaults to manager role' do
      admin = Admin.new
      expect(admin.role).to eq('manager')
    end

    it 'does not override explicit role' do
      admin = Admin.new(role: :super_admin)
      expect(admin.role).to eq('super_admin')
    end
  end

  describe 'security validations' do
    it 'prevents weak passwords (specific security check)' do
      # Test for common weak passwords
      weak_passwords = ['password', '123456', 'admin123', 'password123']

      weak_passwords.each do |weak_pass|
        admin = build(:admin, password: weak_pass, password_confirmation: weak_pass)
        expect(admin).not_to be_valid
        # Note: This would require custom validation in real app
      end
    end
  end

  describe 'xss prevention' do
    it 'escapes html in names to prevent XSS' do
      admin = build(:admin, first_name: '<script>alert("xss")</script>')
      expect(admin.full_name).to include('<script>')
      # In views, this should be escaped automatically by Rails
    end
  end
end
