# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2024, by Samuel Williams.

class Parent
end

class Child < Parent
end

class << self
end

class My::Nested::Child
end

class QualifiedChild < My::Parent
end

class AbsoluteChild < ::Parent
end
