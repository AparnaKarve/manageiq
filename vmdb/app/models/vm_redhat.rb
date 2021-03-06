class VmRedhat < VmInfra
  include_concern 'Operations'

  def provider_object(connection = nil)
    connection ||= self.ext_management_system.connect
    connection.get_resource_by_ems_ref(self.ems_ref)
  end

  def scan_via_ems?
    true
  end

  def parent_cluster
    rp = self.parent_resource_pool
    rp && rp.detect_ancestor(:of_type => "EmsCluster").first
  end
  alias owning_cluster parent_cluster
  alias ems_cluster parent_cluster

  #
  # UI Button Validation Methods
  #

  def has_required_host?
    true
  end
end
