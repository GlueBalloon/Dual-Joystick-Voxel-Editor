--[[
.addPropertyReadOnly("id", &SafeBlockType::blockID)
.addPropertyReadOnly("name", &SafeBlockType::getName)
.addPropertyReadOnly("state", &SafeBlockType::getState)
.addPropertyReadOnly("model", &SafeBlockType::getModel)
.addProperty("geometry", &SafeBlockType::getGeometry, &SafeBlockType::setGeometry)
.addProperty("renderPass", &SafeBlockType::getRenderPass, &SafeBlockType::setRenderPass)
.addProperty("tinted", &SafeBlockType::isTinted, &SafeBlockType::setTinted)
.addProperty("dynamic", &SafeBlockType::isDynamic, &SafeBlockType::setDynamic)
.addProperty("scripted", &SafeBlockType::isScripted, &SafeBlockType::setScripted)
.addFunction("setTexture", &SafeBlockType::setTexture, LUA_ARGS(int, std::string))
.addFunction("setColor", &SafeBlockType::lua_setColor)

Lua::setGlobal(L, "NORTH", BlockFace::North);
Lua::setGlobal(L, "EAST", BlockFace::East);
Lua::setGlobal(L, "SOUTH", BlockFace::South);
Lua::setGlobal(L, "WEST", BlockFace::West);
Lua::setGlobal(L, "UP", BlockFace::Up);
Lua::setGlobal(L, "DOWN", BlockFace::Down);
Lua::setGlobal(L, "NONE", BlockFace::None);
Lua::setGlobal(L, "ALL", BlockFace::All);

// Block State Constants
Lua::setGlobal(L, "BLOCK_ID", Chunk::LuaBlockReturnType::BLOCK_ID);
Lua::setGlobal(L, "BLOCK_NAME", Chunk::LuaBlockReturnType::BLOCK_NAME);
Lua::setGlobal(L, "BLOCK_ENTITY", Chunk::LuaBlockReturnType::BLOCK_ENTITY);
Lua::setGlobal(L, "BLOCK_STATE", Chunk::LuaBlockReturnType::BLOCK_STATE);
Lua::setGlobal(L, "COLOR", Chunk::LuaBlockReturnType::COLOR);
Lua::setGlobal(L, "TORCH_LIGHT", Chunk::LuaBlockReturnType::TORCH_LIGHT);
Lua::setGlobal(L, "LIGHT", Chunk::LuaBlockReturnType::LIGHT);

// Block Geometry Constants
Lua::setGlobal(L, "EMPTY", BlockGeometry::Empty);
Lua::setGlobal(L, "SOLID", BlockGeometry::Solid);
Lua::setGlobal(L, "TRANSPARENT", BlockGeometry::Transparent);

Lua::setGlobal(L, "OPAQUE", BlockRenderPass::Opaque);
Lua::setGlobal(L, "TRANSLUCENT", BlockRenderPass::Translucent);
]]
