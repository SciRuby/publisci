module Prov
  module Element
    def subject(s=nil)
      if s
        if s.is_a? Symbol
          raise "subject generation coming soon!"
        else
          @subject = s
        end
      else
        @subject ||= generate_subject
      end
    end

    def subject=(s)
      @subject = s
    end

    def __label=(l)
      @__label = l
    end

    def __label
      raise "MissingInternalLabel: no __label for #{self.inspect}" unless @__label
      @__label
    end

    private
    def generate_subject
      # puts self.class == Prov::Activity
      category = case self
      when Agent
        "agent"
      when Entity
        "entity"
      when Activity
        "activity"
      when Plan
        "plan"
      else
        raise "MissingSubject: No automatic subject generation for #{self}"
      end
      "#{Prov.base_url}/#{category}/#{__label}"
    end
  end

  def self.register(name,object)
    name = name.to_sym if name
    if object.is_a? Agent
      sub = :agents
    elsif object.is_a? Entity
      sub = :entities
    elsif object.is_a? Activity
      sub = :activities
    elsif object.is_a? Association
      sub = :associations
    elsif object.is_a? Plan
      sub = :plans
    else
      raise "UnknownElement: unkown object type for #{object}"
    end
    if name
      (registry[sub] ||= {})[name] = object
    else
      (registry[sub] ||= []) << object
    end
  end

  def self.registry
    @registry ||= {}
  end

  def self.run(string)
    if File.exists? string
      Prov::DSL::Singleton.new.instance_eval(IO.read(string),string)
    else
      Prov::DSL::Singleton.new.instance_eval(string)
    end
  end

  def self.agents
    registry[:agents] ||= {}
  end

  def self.entities
    registry[:entities] ||= {}
  end

  def self.activities
    registry[:activities] ||= {}
  end

  def self.associations
    registry[:associations] ||= []
  end

  def self.plans
    registry[:plans] ||= {}
  end

  def self.base_url
    @base_url ||= "http://rqtl.org/ns"
  end

  def self.base_url=(url)
    @base_url = url
  end
end