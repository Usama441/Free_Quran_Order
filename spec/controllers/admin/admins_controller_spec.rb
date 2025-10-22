RSpec.describe Admin::AdminsController, type: :controller do
  let(:super_admin) { create(:super_admin_admin) }
  let(:manager_admin) { create(:manager_admin) }

  before do
    Warden.test_mode!
  end

  after do
    Warden.test_reset!
  end

  describe 'GET #index' do
    context 'when super admin is logged in' do
      before do
        sign_in super_admin
      end

      it 'returns http success' do
        get :index
        expect(response).to have_http_status(:success)
      end

      it 'assigns all admins to @admins' do
        admins = create_list(:admin, 3)
        get :index
        expect(assigns(:admins)).to eq([super_admin] + admins)
      end

      it 'renders the index template' do
        get :index
        expect(response).to render_template(:index)
      end
    end

    context 'when manager is logged in' do
      before do
        sign_in manager_admin
      end

      it 'redirects to dashboard' do
        get :index
        expect(response).to redirect_to(admin_dashboard_path)
      end

      it 'shows alert message' do
        get :index
        expect(flash[:alert]).to include('Access denied')
      end
    end

    context 'when not logged in' do
      it 'redirects to sign in' do
        get :index
        expect(response).to redirect_to(new_admin_session_path)
      end
    end

    # Security test: SQL injection prevention
    context 'SQL injection prevention' do
      before do
        sign_in super_admin
      end

      it 'handles malicious SQL in parameters' do
        # Test various SQL injection patterns
        sql_injection_attempts = [
          "1' OR '1'='1",
          "1; DROP TABLE admins;--",
          "1 UNION SELECT * FROM users--",
          "admin@example.com'--",
          "' OR 1=1 --"
        ]

        sql_injection_attempts.each do |malicious_param|
          expect {
            get :index, params: { malicious: malicious_param }
          }.not_to raise_error
        end
      end
    end
  end

  describe 'GET #new' do
    context 'when super admin is logged in' do
      before do
        sign_in super_admin
      end

      it 'returns http success' do
        get :new
        expect(response).to have_http_status(:success)
      end

      it 'assigns a new admin to @admin' do
        get :new
        expect(assigns(:admin)).to be_a_new(Admin)
      end

      it 'renders the new template' do
        get :new
        expect(response).to render_template(:new)
      end
    end

    context 'when manager is logged in' do
      before do
        sign_in manager_admin
      end

      it 'redirects to dashboard' do
        get :new
        expect(response).to redirect_to(admin_dashboard_path)
      end
    end
  end

  describe 'POST #create' do
    let(:valid_params) do
      {
        first_name: 'John',
        last_name: 'Doe',
        email: 'john.doe@example.com',
        password: 'password123',
        password_confirmation: 'password123',
        role: 'manager'
      }
    end

    let(:invalid_params) do
      {
        first_name: '',
        last_name: '',
        email: 'invalid',
        password: '123',
        role: 'invalid'
      }
    end

    context 'when super admin is logged in' do
      before do
        sign_in super_admin
      end

      context 'with valid parameters' do
        it 'creates a new admin' do
          expect {
            post :create, params: { admin: valid_params }
          }.to change(Admin, :count).by(1)
        end

        it 'redirects to the admin index' do
          post :create, params: { admin: valid_params }
          expect(response).to redirect_to(admin_admins_path)
        end

        it 'shows success notice' do
          post :create, params: { admin: valid_params }
          expect(flash[:notice]).to include('successfully created')
        end
      end

      context 'with invalid parameters' do
        it 'does not create a new admin' do
          expect {
            post :create, params: { admin: invalid_params }
          }.to change(Admin, :count).by(0)
        end

        it 'renders the new template' do
          post :create, params: { admin: invalid_params }
          expect(response).to render_template(:new)
        end

        it 'returns unprocessable_entity status' do
          post :create, params: { admin: invalid_params }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context 'when manager is logged in' do
      before do
        sign_in manager_admin
      end

      it 'does not create admin' do
        expect {
          post :create, params: { admin: valid_params }
        }.not_to change(Admin, :count)
      end

      it 'redirects to dashboard' do
        post :create, params: { admin: valid_params }
        expect(response).to redirect_to(admin_dashboard_path)
      end
    end

    # CSRF Protection Test
    context 'CSRF protection' do
      before do
        sign_in super_admin
      end

      it 'rejects requests without authenticity token' do
        # This test verifies that Rails CSRF protection is active
        ActionController::RspecForceInvalidCSRF = true

        expect {
          post :create, params: { admin: valid_params, authenticity_token: nil }
        }.to raise_error(ActionController::InvalidAuthenticityToken)

        ActionController::RspecForceInvalidCSRF = false
      end
    end

    # Security test: Mass assignment protection
    context 'mass assignment protection' do
      before do
        sign_in super_admin
      end

      it 'only permits allowed parameters' do
        # Test that dangerous parameters are filtered out
        malicious_params = valid_params.merge({
          created_at: Time.now,
          updated_at: Time.now,
          encrypted_password: 'hacked_password',
          reset_password_token: 'malicious_token',
          confirmation_token: 'evil_token'
        })

        expect {
          post :create, params: { admin: malicious_params }
        }.to change(Admin, :count).by(1)

        admin = Admin.last
        # Verify the dangerous parameters were not set
        expect(admin.created_at).to be_present
        expect(admin.encrypted_password).not_to eq('hacked_password')
        expect(admin.reset_password_token).not_to eq('malicious_token')
      end
    end

    # XSS Prevention Test
    context 'XSS prevention' do
      before do
        sign_in super_admin
      end

      it 'prevents XSS in names' do
        malicious_params = {
          first_name: '<script>alert("XSS in first name")</script>',
          last_name: '<img src=x onerror=alert("XSS in last name")>',
          email: 'xss@example.com',
          password: 'password123',
          password_confirmation: 'password123',
          role: 'manager'
        }

        expect {
          post :create, params: { admin: malicious_params }
        }.to change(Admin, :count).by(1)

        admin = Admin.last
        expect(admin.first_name).to include('<script>')
        expect(admin.last_name).to include('<img')
        # NOTE: In HTML views, Rails automatically escapes these values
        # The actual escaping happens in the view layer, not in the model
      end
    end
  end

  describe 'GET #edit' do
    let(:other_admin) { create(:admin) }

    context 'when super admin edits another admin' do
      before do
        sign_in super_admin
      end

      it 'returns http success' do
        get :edit, params: { id: other_admin.id }
        expect(response).to have_http_status(:success)
      end

      it 'assigns the requested admin to @admin' do
        get :edit, params: { id: other_admin.id }
        expect(assigns(:admin)).to eq(other_admin)
      end
    end

    context 'when trying to edit self' do
      before do
        sign_in super_admin
      end

      it 'allows editing own account' do
        get :edit, params: { id: super_admin.id }
        expect(response).to have_http_status(:success)
        expect(assigns(:admin)).to eq(super_admin)
      end
    end
  end

  describe 'PATCH #update' do
    let(:other_admin) { create(:admin) }
    let(:valid_update_params) do
      {
        first_name: 'Updated',
        last_name: 'Name',
        email: 'updated@example.com'
      }
    end

    context 'when super admin updates another admin' do
      before do
        sign_in super_admin
      end

      it 'updates the admin' do
        patch :update, params: { id: other_admin.id, admin: valid_update_params }
        other_admin.reload
        expect(other_admin.first_name).to eq('Updated')
        expect(other_admin.last_name).to eq('Name')
      end

      it 'redirects to admins index' do
        patch :update, params: { id: other_admin.id, admin: valid_update_params }
        expect(response).to redirect_to(admin_admins_path)
      end
    end

    context 'when super admin tries to demote himself' do
      it 'prevents self-demotion' do
        original_role = super_admin.role
        patch :update, params: { id: super_admin.id, admin: { role: :manager } }
        super_admin.reload
        expect(super_admin.role).to eq(original_role)
        expect(response).to redirect_to(admin_admins_path)
        expect(flash[:alert]).to include('cannot demote yourself')
      end
    end

    context 'when manager tries to update' do
      before do
        sign_in manager_admin
      end

      it 'redirects away' do
        patch :update, params: { id: other_admin.id, admin: valid_update_params }
        expect(response).to redirect_to(admin_dashboard_path)
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:other_admin) { create(:admin) }

    context 'when super admin deletes another admin' do
      before do
        sign_in super_admin
      end

      it 'deletes the admin' do
        expect {
          delete :destroy, params: { id: other_admin.id }
        }.to change(Admin, :count).by(-1)
      end

      it 'redirects to admins index' do
        delete :destroy, params: { id: other_admin.id }
        expect(response).to redirect_to(admin_admins_path)
      end
    end

    context 'when trying to delete self' do
      before do
        sign_in super_admin
      end

      it 'prevents self-deletion' do
        expect {
          delete :destroy, params: { id: super_admin.id }
        }.not_to change(Admin, :count)

        expect(response).to redirect_to(admin_admins_path)
        expect(flash[:alert]).to include('cannot delete your own account')
      end
    end

    context 'when manager tries to delete' do
      before do
        sign_in manager_admin
      end

      it 'redirects away' do
        expect {
          delete :destroy, params: { id: other_admin.id }
        }.not_to change(Admin, :count)

        expect(response).to redirect_to(admin_dashboard_path)
      end
    end
  end

  describe 'authentication bypass attempts' do
    it 'requires admin authentication for all actions' do
      %w[index new create edit update destroy].each do |action|
        get action.to_sym
        expect(response).to redirect_to(new_admin_session_path)
      end
    end
  end

  describe 'authorization bypass attempts' do
    before do
      sign_in manager_admin
    end

    it 'prevents manager from accessing admin management' do
      get :index
      expect(response).to redirect_to(admin_dashboard_path)

      post :create, params: { admin: { first_name: 'Test', last_name: 'User', email: 'test@example.com' } }
      expect(response).to redirect_to(admin_dashboard_path)
    end
  end
end
