core = {}

jit.off() -- Use non-FFI versions of CPML
core.vec2 = require 'https://raw.githubusercontent.com/excessive/cpml/master/modules/vec2.lua'
core.color = require 'https://raw.githubusercontent.com/excessive/cpml/master/modules/color.lua'
--core.vec3 = cpml.vec3
--core.quat = cpml.quat
--core.bound2 = cpml.bound2
--core.bound3 = cpml.bound3
jit.on()


require 'core.entity'
require 'core.spatial'
require 'core.visual'
require 'core.sprite'

return core