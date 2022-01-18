--- Royal Utility

---@author Royal Modding
---@version 2.1.1.0
---@date 05/01/2021

---@class EntityUtility
EntityUtility = EntityUtility or {}

--- Get the class id and name of an onject
---@param objectId integer
---@return integer classId class id
---@return string className class name
function EntityUtility.getObjectClass(objectId)
    if objectId == nil then
        return nil, nil
    end
    for name, id in pairs(ClassIds) do
        if getHasClassId(objectId, id) then
            return id, name
        end
    end
end

--- Determines whether a node is a child of a given node
---@param childNode integer
---@param parentNode integer
---@return boolean
function EntityUtility.isChildOf(childNode, parentNode)
    if childNode == nil or childNode == 0 or parentNode == nil or parentNode == 0 then
        return false
    end
    local pNode = getParent(childNode)
    while pNode ~= 0 do
        if pNode == parentNode then
            return true
        end
        pNode = getParent(pNode)
    end
    return false
end

--- Get the node index relative to root node
---@param nodeId integer id of node
---@param rootId integer id of root node
---@return string nodeIndex index of node
function EntityUtility.nodeToIndex(nodeId, rootId)
    local index = ""
    if nodeId ~= nil and entityExists(nodeId) and rootId ~= nil and entityExists(rootId) and EntityUtility.isChildOf(nodeId, rootId) then
        index = tostring(getChildIndex(nodeId))
        local pNode = getParent(nodeId)
        while pNode ~= rootId and pNode ~= 0 do
            index = string.format("%s|%s", getChildIndex(pNode), index)
            pNode = getParent(pNode)
        end
    end
    return index
end

--- Get a node id by an index
---@param nodeIndex string index of node
---@param rootId integer id of root node
---@return integer nodeId id of node
function EntityUtility.indexToNode(nodeIndex, rootId)
    if nodeIndex == nil or rootId == nil or not entityExists(rootId) then
        return nil
    end
    local objectId = rootId
    local indexes = StringUtility.split(nodeIndex, "|")
    for _, index in pairs(indexes) do
        index = tonumber(index)
        if type(index) == "number" then
            if getNumOfChildren(objectId) >= index then
                objectId = getChildAt(objectId, index)
            else
                return nil
            end
        else
            return nil
        end
    end
    return objectId
end

--- Queries a node hierarchy
---@param inputNode integer
---@param func fun(node: integer, name: string, depth: integer)
function EntityUtility.queryNodeHierarchy(inputNode, func)
    if not type(inputNode) == "number" or not entityExists(inputNode) or func == nil then
        return
    end
    local function queryNodeHierarchyRecursively(node, depth)
        func(node, getName(node), depth)
        for i = 0, getNumOfChildren(node) - 1 do
            queryNodeHierarchyRecursively(getChildAt(node, i), depth + 1)
        end
    end
    local depth = 1
    func(inputNode, getName(inputNode), depth)
    for i = 0, getNumOfChildren(inputNode) - 1 do
        queryNodeHierarchyRecursively(getChildAt(inputNode, i), depth + 1)
    end
end

--- Get the hash of a node hierarchy
---@param node integer
---@param parent integer
---@param md5 boolean
---@return string hash hash of the node hierarchy
function EntityUtility.getNodeHierarchyHash(node, parent, md5)
    if not type(node) == "number" or not entityExists(node) or not type(parent) == "number" or not entityExists(parent) then
        return string.format("Invalid hash node:%s parent:%s", node, parent)
    end
    local hash = ""
    local nodeCount = 0

    local floatsToString = function(...)
        local ret = {}
        for i, v in ipairs({...}) do
            local tV = string.format("%.1f", v)
            if tV == "-0.0" then
                tV = "0.0"
            end
            ret[i] = tV
        end
        return table.concat(ret, "|")
    end

    local isDyna = false

    EntityUtility.queryNodeHierarchy(
        node,
        function(n, name)
            local rbt = getRigidBodyType(n)
            if rbt == "Dynamic" then
                isDyna = true
            end
            local pos = ""
            local rot = ""
            if not isDyna then
                pos = floatsToString(getWorldTranslation(n))
                rot = floatsToString(getWorldRotation(n))
            end
            local sca = floatsToString(getScale(n))
            local index = EntityUtility.nodeToIndex(node, parent)
            local vis = getVisibility(n)
            hash = string.format("%s>->%s->%s->%s->%s->%s->%s->%s", hash, name, pos, rot, sca, index, rbt, vis)
            nodeCount = nodeCount + 1
        end
    )
    if md5 then
        return getMD5(string.format("%s%s_dMs5AsHZWy", hash, nodeCount))
    else
        return string.format("%s___%s", hash, nodeCount)
    end
end

--- Queries node parents (return false to break the loop)
---@param inputNode integer
---@param func function | "function(node, name, depth) return true end"
function EntityUtility.queryNodeParents(inputNode, func)
    if not type(inputNode) == "number" or not entityExists(inputNode) or func == nil then
        return
    end
    local depth = 1
    local pNode = inputNode
    while pNode ~= 0 do
        if not func(pNode, getName(pNode), depth) then
            break
        end
        pNode = getParent(pNode)
        depth = depth + 1
    end
end
