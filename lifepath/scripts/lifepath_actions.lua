LIFEPATH_CREATE_NOTE = "lifepath_create_note"
LIFEPATH_GET_TALENTS = "lifepath_get_talents"
LIFEPATH_TALENTS_CALLBACK = "lifepath_talents_callback"

LIFEPATH_ROOT_NODE_REQUEST = "lifepath_root_node_request"
LIFEPATH_ROOT_NODE_RESPONSE = "lifepath_root_node_response"
GM_USER = "GM"
LP_NODE_ROOT = "lp_wizard"

function onInit()
    OOBManager.registerOOBMsgHandler(LIFEPATH_CREATE_NOTE, handleCreateNote)
    OOBManager.registerOOBMsgHandler(LIFEPATH_GET_TALENTS, handleCharacterTalentRequest)
    OOBManager.registerOOBMsgHandler(LIFEPATH_ROOT_NODE_REQUEST, handleRootNodeRequest)
end

function handleCreateNote(oobMsg)
    if User.isHost() or User.isLocal() then
        local node = DB.createChild("notes");
        node.createChild("name", "string").setValue(oobMsg.name)
        node.createChild("text", "formattedtext").setValue(oobMsg.text);
        DB.setOwner(node, oobMsg.user)
        local oobMsgBack = {["type"]=oobMsg.callback, ["node"]=node.getNodeName(), ["name"]=oobMsg.name}
        Comm.deliverOOBMessage(oobMsgBack, oobMsg.user);
    end
end

function handleCharacterTalentRequest(oobMsg)
    if User.isHost() or User.isLocal() then
        local reply = LifePathActionHelper.getCharacterTalents(oobMsg.ship_mode=="true")
        reply["type"] = oobMsg.callback
        Comm.deliverOOBMessage(reply, oobMsg.user)
    end
end

function getCharacterTalents(ship_mode)
    local talents = {}
    if STAModuleManager.modLoaded(STAModuleManager.MODULE_MAIN) then
        for talent, node in pairs(DB.findNode(STAModuleManager.getPathMain("reference.talents")).getChildren()) do
            if ship_mode == (node.getCategory() == "Starship Talents") then
                talents["("..node.getCategory()..") "..node.getChild("name").getValue()] = node.getNodeName()
            end
        end
    end
    return talents
end

function createNode(user)
    local node = DB.createChild(LP_NODE_ROOT, user)
    DB.deleteChildren(node)
    if not (user==GM_USER) then DB.setOwner(node, user) end
    return node
end

function handleRootNodeRequest(oobMsg)
    if User.isHost() or User.isLocal() then
        local node = createNode(oobMsg["user"])
        local response = {
            ["type"]=oobMsg.callback,
            ["user"]=oobMsg.user,
            ["nodeName"]=node.getNodeName()
        }
        Comm.deliverOOBMessage(response, oobMsg.user);
    end
end

function requestRootNode(callbackFunc)
    local oobMsg = {
        ["type"]=LIFEPATH_ROOT_NODE_REQUEST,
        ["user"]=User.getUsername(),
        ["callback"]=LIFEPATH_ROOT_NODE_RESPONSE..User.getUsername()
    }
    OOBManager.registerOOBMsgHandler(oobMsg.callback, callbackFunc)
    Comm.deliverOOBMessage(oobMsg, "");
end