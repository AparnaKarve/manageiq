class MiqAeInstance < ActiveRecord::Base
  include MiqAeSetUserInfoMixin
  include MiqAeYamlImportExportMixin

  belongs_to :ae_class,  :class_name => "MiqAeClass", :foreign_key => :class_id,    :include => :ae_fields
  has_many   :ae_values, :class_name => "MiqAeValue", :foreign_key => :instance_id, :include => :ae_field, :dependent => :destroy

  validates_uniqueness_of :name, :case_sensitive => false, :scope => :class_id
  validates_presence_of   :name
  validates_format_of     :name, :with => /\A[A-Za-z0-9_.-]+\z/i

  include ReportableMixin

  def self.find_by_name(name)
    self.find(:first, :conditions => ["lower(name) = ?", name.downcase])
  end

  def get_field_attribute(field, validate, attribute)
    if validate
      field, fname = validate_field(field)
      raise MiqAeException::FieldNotFound, "Field [#{fname}] not found in MiqAeDatastore" if field.nil?
    end

    val = self.ae_values.detect { |v| v.field_id == field.id }
    val.respond_to?(attribute) ? val.send(attribute) : nil
  end

  def set_field_attribute(field, value, attribute)
    field, fname = validate_field(field)
    raise MiqAeException::FieldNotFound, "Field [#{fname}] not found in MiqAeDatastore" if field.nil?

    val   = self.ae_values.detect { |v| v.field_id == field.id }
    val ||= self.ae_values.build(:field_id => field.id)
    val.send("#{attribute.to_s}=", value)
    val.save!
  end

  def get_field_collect(field, validate = true)
    get_field_attribute(field, validate, :collect)
  end

  def set_field_collect(field, value)
    set_field_attribute(field, value, :collect)
  end

  def get_field_value(field, validate = true)
    get_field_attribute(field, validate, :value)
  end

  def set_field_value(field, value)
    set_field_attribute(field, value, :value)
  end

  def field_attributes
    result = {}
    self.ae_class.ae_fields.each do |f|
      result[f.name] = self.get_field_value(f, false)
    end
    return result
  end

  def fqname
    "#{self.ae_class.fqname}/#{self.name}"
  end

  def export_ae_fields
    ae_values_sorted.collect(&:to_export_yaml).compact
  end

  # TODO: Limit search to within the context of a class id?
  def self.search(str)
    str[-1,1] = "%" if str[-1,1] == "*"
    self.find(:all, :conditions => ["lower(name) LIKE ?", str.downcase]).collect { |i| i.name }
  end

  def to_export_xml(options = {})
    require 'builder'
    xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])
    xml_attrs = { :name => self.name }

    self.class.column_names.each { |cname|
      # Remove any columns that we do not want to export
      next if ["id", "created_on", "updated_on", "updated_by", "reserved"].include?(cname) || cname.ends_with?("_id")

      # Skip any columns that we process explicitly
      next if ["name"].include?(cname)

      # Process the column
      xml_attrs[cname.to_sym]  = self.send(cname)   unless self.send(cname).blank?
    }

    xml.MiqAeInstance(xml_attrs) {
      self.ae_values_sorted.each { |v| v.to_export_xml(:builder => xml) }
    }
  end

  def ae_values_sorted
   self.ae_class.ae_fields.sort_by { |field| field.priority }.collect { |field| self.ae_values.find_by_field_id(field.id) }.compact
  end

  def editable?
    ae_class.ae_namespace.editable?
  end

  private


  def validate_field(field)
    if field.kind_of?(MiqAeField)
      fname = field.name
      field = nil unless self.ae_class.ae_fields.include?(field)
    else
      fname = field
      field = self.ae_class.ae_fields.detect { |f| fname.casecmp(f.name) == 0 }
    end
    return field, fname
  end
end
