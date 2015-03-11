#encoding: utf-8
# Hack to Hash to we can use
# the private binding() method on ERB.
class Hash
  def get_binding # rubocop:disable AccessorMethodName
    binding()
  end
end

# Hack to OpenStruct to we can use
# the private binding() method on ERB.
class OpenStruct
  def get_binding # rubocop:disable AccessorMethodName
    binding()
  end
end

# Documentation for String
# Implement camelize and underscope
class String
  def camelize
    self.split("_").each(&:capitalize!).join("")
  end

  def underscore
    self.gsub(/(.)([A-Z])/,'\1_\2').downcase
  end
end
