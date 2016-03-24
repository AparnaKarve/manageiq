class EmsInfraController < ApplicationController
  include EmsCommon        # common methods for EmsInfra/Cloud controllers
  include Mixins::EmsCommonAngular

  before_action :check_privileges
  before_action :get_session_data
  after_action :cleanup_action
  after_action :set_session_data

  def self.model
    ManageIQ::Providers::InfraManager
  end

  def self.table_name
    @table_name ||= "ems_infra"
  end

  def ems_path(*args)
    ems_infra_path(*args)
  end

  def index
    redirect_to :action => 'show_list'
  end

  def scaling
    assert_privileges("ems_infra_scale")

    # Hiding the toolbars
    @in_a_form = true

    redirect_to :action => 'show', :id => params[:id] if params[:cancel]

    drop_breadcrumb(:name => _("Scale Infrastructure Provider"), :url => "/ems_infra/scaling")
    @infra = ManageIQ::Providers::Openstack::InfraManager.find(params[:id])
    # TODO: Currently assumes there is a single stack per infrastructure provider. This should
    # be improved to support multiple stacks.
    @stack = @infra.direct_orchestration_stacks.first
    if @stack.nil?
      log_and_flash_message(_("Orchestration stack could not be found."))
      return
    end

    @count_parameters = @stack.parameters.select { |x| x.name.include?('::count') || x.name.include?('Count') }

    return unless params[:scale]

    scale_parameters = params.select { |k, _v| k.include?('::count') || k.include?('Count') }.to_unsafe_h
    assigned_hosts = scale_parameters.values.sum(&:to_i)
    infra = ManageIQ::Providers::Openstack::InfraManager.find(params[:id])
    if assigned_hosts > infra.hosts.count
      # Validate number of selected hosts is not more than available
      log_and_flash_message(_("Assigning %{hosts} but only have %{hosts_count} hosts available.") % {:hosts => assigned_hosts, :hosts_count => infra.hosts.count.to_s})
    else
      scale_parameters_formatted = {}
      return_message = _("Scaling")
      @count_parameters.each do |p|
        if !scale_parameters[p.name].nil? && scale_parameters[p.name] != p.value
          return_message += _(" %{name} from %{value} to %{parameters} ") % {:name => p.name, :value => p.value, :parameters => scale_parameters[p.name]}
          scale_parameters_formatted[p.name] = scale_parameters[p.name]
        end
      end

      begin
        # Check if stack is ready to be updated
        update_ready = @stack.update_ready?
      rescue => ex
        log_and_flash_message(_("Unable to initiate scaling, obtaining of status failed: %{message}") %
                                {:message => ex})
        return
      end

      if !update_ready
        add_flash(_("Provider is not ready to be scaled, another operation is in progress."), :error)
      elsif scale_parameters_formatted.length > 0
        # A value was changed
        begin
          @stack.raw_update_stack(nil, scale_parameters_formatted)
          redirect_to :action => 'show', :id => params[:id], :flash_msg => return_message
        rescue => ex
          log_and_flash_message(_("Unable to initiate scaling: %{message}") % {:message => ex})
        end
      else
        # No values were changed
        add_flash(_("A value must be changed or provider will not be scaled."), :error)
      end
    end
  end

  def ems_infra_form_fields
    assert_privileges("#{permission_prefix}_edit")
    @ems = model.new if params[:id] == 'new'
    @ems = find_by_id_filtered(model, params[:id]) if params[:id] != 'new'

    if @ems.zone.nil? || @ems.my_zone == ""
      zone = "default"
    else
      zone = @ems.my_zone
    end

    amqp_userid = @ems.has_authentication_type?(:amqp) ? @ems.authentication_userid(:amqp).to_s : ""
    ssh_keypair_userid = @ems.has_authentication_type?(:ssh_keypair) ? @ems.authentication_userid(:ssh_keypair).to_s : ""

    if @ems.kind_of?(ManageIQ::Providers::Openstack::InfraManager)
      security_protocol = @ems.security_protocol ? @ems.security_protocol : 'ssl'
    else
      if @ems.id
        security_protocol = @ems.security_protocol ? @ems.security_protocol : 'ssl'
      else
        security_protocol = 'kerberos'
      end
    end

    @ems_types = Array(model.supported_types_and_descriptions_hash.invert).sort_by(&:first)

    if @ems.kind_of?(ManageIQ::Providers::Vmware::InfraManager)
      host_default_vnc_port_start = @ems.host_default_vnc_port_start.to_s
      host_default_vnc_port_end = @ems.host_default_vnc_port_end.to_s
    end

    render :json => {:name                            => @ems.name,
                     :provider_region                 => @ems.provider_region,
                     :emstype                         => @ems.emstype,
                     :zone                            => zone,
                     :provider_id                     => @ems.provider_id ? @ems.provider_id : "",
                     :hostname                        => @ems.hostname,
                     :api_port                        => @ems.port,
                     :api_version                     => @ems.api_version,
                     :security_protocol               => security_protocol,
                     :provider_region                 => @ems.provider_region,
                     :default_userid                  => @ems.authentication_userid ? @ems.authentication_userid : "",
                     :amqp_userid                     => amqp_userid,
                     :ssh_keypair_userid              => ssh_keypair_userid,
                     :emstype_vm                      => @ems.kind_of?(ManageIQ::Providers::Vmware::InfraManager),
                     :host_default_vnc_port_start     => host_default_vnc_port_start ? host_default_vnc_port_start : "",
                     :host_default_vnc_port_end       => host_default_vnc_port_end ? host_default_vnc_port_end : ""
    }
  end

  private

  ############################
  # Special EmsCloud link builder for restful routes
  def show_link(ems, options = {})
    ems_path(ems.id, options)
  end

  def log_and_flash_message(message)
    add_flash(message, :error)
    $log.error(message)
  end

  def restful?
    true
  end
  public :restful?
end
