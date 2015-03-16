require "spec_helper"

describe ProviderForemanController do
  render_views
  before(:each) do
    set_user_privileges
    @zone = FactoryGirl.create(:zone, :name => 'zone1')
    @provider = ProviderForeman.create(:name => "test", :url => "10.8.96.102", :verify_ssl => nil, :zone => @zone)
    @config_mgr_foreman = ConfigurationManagerForeman.find_all_by_provider_id(@provider).first
    @config_profile = ConfigurationProfileForeman.create(:name                     => "testprofile",
                                                         :configuration_manager_id => @config_mgr_foreman.id)
    sb = {}
    temp = {}
    sb[:active_tree] = :foreman_providers_tree
    controller.instance_variable_set(:@sb, sb)
    controller.instance_variable_set(:@temp, temp)
  end

  it "renders index" do
    get :index
    expect(response.status).to eq(302)
    response.should redirect_to(:action => 'explorer')
  end

  it "renders explorer" do
    get :explorer
    expect(response.status).to eq(200)
  end

  it "renders show_list" do
    get :show_list
    expect(response.status).to eq(302 )
    expect(response.body).to_not be_empty
  end

  it "renders a new page" do
    session[:settings] = {:views => {}, :perpage => {:list => 10}}
    post :new, :format => :js
    expect(response.status).to eq(200)
  end

  context "renders right cell text" do
    before do
      right_cell_text = nil
      controller.instance_variable_set(:@right_cell_text, right_cell_text)
      controller.stub(:process_show_list)
      controller.send(:build_foreman_tree, :providers, :foreman_providers_tree)
    end
    it "renders right cell text for root node" do
      key = ems_key_for_provider(@provider)
      controller.send(:get_node_info, key)
      right_cell_text = controller.instance_variable_get(:@right_cell_text)
      expect(right_cell_text).to eq("All Foreman Providers")
    end

    it "renders right cell text for ConfigurationManagerForeman node" do
      key = ems_key_for_provider(@provider)
      controller.send(:x_node_set, key, :foreman_providers_tree)
      controller.send(:get_node_info, key)
      right_cell_text = controller.instance_variable_get(:@right_cell_text)
      expect(right_cell_text).to eq("Provider \"test Configuration Manager\"")
    end
  end

  it "builds foreman tree" do
    controller.send(:build_foreman_tree, :providers, :foreman_providers_tree)
    first_child = find_treenode_for_provider(@provider)
    expect(first_child["title"]).to eq("test Configuration Manager")
  end

  context "renders x_show" do
    it "renders x_show when the the node is a ConfigurationManagerForeman node" do
      ems_id = ems_id_to_retrieve_record(@provider)
      sb = {}
      sb[:active_tree] = :foreman_providers_tree
      controller.stub(:x_active_tree).and_return(:foreman_providers_tree)
      post :x_show, :format => :js
      expect(response.status).to eq(200)
      puts response.body
    end
  end

  def find_treenode_for_provider(provider)
    key =  ems_key_for_provider(provider)
    temp = controller.instance_variable_get(:@temp)
    tree =  JSON.parse(temp[:foreman_providers_tree])
    tree[0]['children'].find { |c| c['key'] == key }
  end

  def ems_key_for_provider(provider)
    ems = ExtManagementSystem.where(:provider_id => provider.id).first
    "e-" + ActiveRecord::Base.compress_id(ems.id)
    #return "e-10r327"
  end

  def ems_id_to_retrieve_record(provider)
    ems = ExtManagementSystem.where(:provider_id => provider.id).first
    ems.id
  end
end
