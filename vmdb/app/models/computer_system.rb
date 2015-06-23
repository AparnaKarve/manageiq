class ComputerSystem < ActiveRecord::Base
  include ReportableMixin

  belongs_to :managed_entity, :polymorphic => true

  has_one :operating_system, :dependent => :destroy
  has_one :hardware, :dependent => :destroy
end
