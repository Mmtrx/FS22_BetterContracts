--- Royal Utility

---@author Royal Modding
---@version 1.8.1.0
---@date 05/01/2021

--- Render a table (for debugging purpose)
---@param posX number
---@param posY number
---@param textSize number
---@param inputTable table
---@param maxDepth integer|nil
---@param hideFunc boolean|nil
function Utility.renderTable(posX, posY, textSize, inputTable, maxDepth, hideFunc)
    inputTable = inputTable or {tableIs = "nil"}
    hideFunc = hideFunc or false
    maxDepth = maxDepth or 2

    local function renderTableRecursively(x, t, depth, i)
        if depth >= maxDepth then
            return i
        end
        for k, v in pairs(t) do
            local vType = type(v)
            if not hideFunc or vType ~= "function" then
                local offset = i * textSize * 1.05
                setTextAlignment(RenderText.ALIGN_RIGHT)
                renderText(x, posY - offset, textSize, tostring(k) .. " :")
                setTextAlignment(RenderText.ALIGN_LEFT)
                if vType ~= "table" then
                    renderText(x, posY - offset, textSize, " " .. tostring(v))
                end
                i = i + 1
                if vType == "table" then
                    i = renderTableRecursively(x + textSize * 1.8, v, depth + 1, i)
                end
            end
        end
        return i
    end

    local i = 0
    setTextColor(1, 1, 1, 1)
    setTextBold(false)
    textSize = getCorrectTextSize(textSize)
    for k, v in pairs(inputTable) do
        local vType = type(v)
        if not hideFunc or vType ~= "function" then
            local offset = i * textSize * 1.05
            setTextAlignment(RenderText.ALIGN_RIGHT)
            renderText(posX, posY - offset, textSize, tostring(k) .. " :")
            setTextAlignment(RenderText.ALIGN_LEFT)
            if vType ~= "table" then
                renderText(posX, posY - offset, textSize, " " .. tostring(v))
            end
            i = i + 1
            if vType == "table" then
                i = renderTableRecursively(posX + textSize * 1.8, v, 1, i)
            end
        end
    end
end

--- Render a node hierarchy (for debugging purpose)
---@param posX number
---@param posY number
---@param textSize number
---@param inputNode integer
---@param maxDepth integer|nil
function Utility.renderNodeHierarchy(posX, posY, textSize, inputNode, maxDepth)
    if inputNode == nil or inputNode == 0 then
        return
    end
    if type(inputNode) == "number" and entityExists(inputNode) then
        maxDepth = maxDepth or math.huge

        local function renderNodeHierarchyRecursively(x, node, depth, i)
            if depth >= maxDepth then
                return i
            end
            local offset = i * textSize * 1.05
            local _, className = Utility.getObjectClass(node)
            renderText(x, posY - offset, textSize, string.format("%s (%s)", getName(node), className))
            i = i + 1
            for ni = 0, getNumOfChildren(node) - 1 do
                i = renderNodeHierarchyRecursively(x + textSize * 1.8, getChildAt(node, ni), depth + 1, i)
            end
            return i
        end

        local i = 1
        setTextColor(1, 1, 1, 1)
        setTextBold(false)
        textSize = getCorrectTextSize(textSize)
        local _, className = Utility.getObjectClass(inputNode)
        renderText(posX, posY, textSize, string.format("%s (%s)", getName(inputNode), className))
        for ni = 0, getNumOfChildren(inputNode) - 1 do
            i = renderNodeHierarchyRecursively(posX + textSize * 1.8, getChildAt(inputNode, ni), 1, i)
        end
    end
end

--- Draw a rectangle (for debugging purpose)
---@param node integer ref node
---@param minX number minX
---@param maxX number maxX
---@param minZ number minZ
---@param maxZ number maxZ
---@param yOffset number height offset
---@param alignToGround boolean alignToGround
---@param r number r
---@param g number g
---@param b number b
---@param ar number r color if active
---@param ag number g color if active
---@param ab number b color if active
---@param active boolean active?
function Utility.drawDebugRectangle(node, minX, maxX, minZ, maxZ, yOffset, alignToGround, r, g, b, ar, ag, ab, active)
    if active then
        r, g, b = ar, ag, ab
    end

    local leftFrontX, leftFrontY, leftFrontZ = localToWorld(node, minX, yOffset, maxZ)
    local rightFrontX, rightFrontY, rightFrontZ = localToWorld(node, maxX, yOffset, maxZ)

    local leftBackX, leftBackY, leftBackZ = localToWorld(node, minX, yOffset, minZ)
    local rightBackX, rightBackY, rightBackZ = localToWorld(node, maxX, yOffset, minZ)

    if alignToGround then
        leftFrontY = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, leftFrontX, 0, leftFrontZ) + yOffset + 0.1
        rightFrontY = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, rightFrontX, 0, rightFrontZ) + yOffset + 0.1
        leftBackY = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, leftBackX, 0, leftBackZ) + yOffset + 0.1
        rightBackY = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, rightBackX, 0, rightBackZ) + yOffset + 0.1
    end

    drawDebugLine(leftFrontX, leftFrontY, leftFrontZ, r, g, b, rightFrontX, rightFrontY, rightFrontZ, r, g, b)
    drawDebugLine(rightFrontX, rightFrontY, rightFrontZ, r, g, b, rightBackX, rightBackY, rightBackZ, r, g, b)
    drawDebugLine(rightBackX, rightBackY, rightBackZ, r, g, b, leftBackX, leftBackY, leftBackZ, r, g, b)
    drawDebugLine(leftBackX, leftBackY, leftBackZ, r, g, b, leftFrontX, leftFrontY, leftFrontZ, r, g, b)
end

--- Draw a cube (for debugging purpose)
---@param node integer|table ref node or ref position
---@param size number size
---@param r number r
---@param g number g
---@param b number b
---@param ar number r color if active
---@param ag number g color if active
---@param ab number b color if active
---@param active boolean active?
function Utility.drawDebugCube(node, size, r, g, b, ar, ag, ab, active)
    if active then
        r, g, b = ar, ag, ab
    end

    local x, y, z = 0, 0, 0
    if type(node) == "table" then
        x = node[1]
        y = node[2]
        z = node[3]
    else
        x, y, z = getWorldTranslation(node)
    end

    local offsets = size / 2
    local corners = {}
    corners[1] = {x + offsets, y + offsets, z + offsets}
    corners[2] = {x + offsets, y + offsets, z - offsets}
    corners[3] = {x + offsets, y - offsets, z - offsets}
    corners[4] = {x + offsets, y - offsets, z + offsets}
    corners[5] = {x - offsets, y + offsets, z + offsets}
    corners[6] = {x - offsets, y + offsets, z - offsets}
    corners[7] = {x - offsets, y - offsets, z - offsets}
    corners[8] = {x - offsets, y - offsets, z + offsets}

    Utility.drawDebugLine(corners[1], corners[2], 0, 0, 0)
    Utility.drawDebugLine(corners[2], corners[3], 0, 0, 0)
    Utility.drawDebugLine(corners[3], corners[4], 0, 0, 0)
    Utility.drawDebugLine(corners[4], corners[1], 0, 0, 0)
    Utility.drawDebugLine(corners[1], corners[5], 0, 0, 0)
    Utility.drawDebugLine(corners[2], corners[6], 0, 0, 0)
    Utility.drawDebugLine(corners[3], corners[7], 0, 0, 0)
    Utility.drawDebugLine(corners[4], corners[8], 0, 0, 0)
    Utility.drawDebugLine(corners[5], corners[6], 0, 0, 0)
    Utility.drawDebugLine(corners[6], corners[7], 0, 0, 0)
    Utility.drawDebugLine(corners[7], corners[8], 0, 0, 0)
    Utility.drawDebugLine(corners[8], corners[5], 0, 0, 0)

    Utility.drawDebugTriangle(corners[3], corners[2], corners[1], r, g, b)
    Utility.drawDebugTriangle(corners[1], corners[4], corners[3], r, g, b)
    Utility.drawDebugTriangle(corners[4], corners[1], corners[5], r, g, b)
    Utility.drawDebugTriangle(corners[5], corners[8], corners[4], r, g, b)
    Utility.drawDebugTriangle(corners[8], corners[5], corners[6], r, g, b)
    Utility.drawDebugTriangle(corners[6], corners[7], corners[8], r, g, b)
    Utility.drawDebugTriangle(corners[7], corners[6], corners[2], r, g, b)
    Utility.drawDebugTriangle(corners[2], corners[3], corners[7], r, g, b)
    Utility.drawDebugTriangle(corners[2], corners[6], corners[5], r, g, b)
    Utility.drawDebugTriangle(corners[5], corners[1], corners[2], r, g, b)
    Utility.drawDebugTriangle(corners[4], corners[8], corners[7], r, g, b)
    Utility.drawDebugTriangle(corners[7], corners[3], corners[4], r, g, b)
end

--- Draw a triangle (for debugging purpose)
---@param c1 table first corner position {x, y, z}
---@param c2 table second corner position {x, y, z}
---@param c3 table third corner position {x, y, z}
---@param r number r
---@param g number g
---@param b number b
function Utility.drawDebugTriangle(c1, c2, c3, r, g, b)
    drawDebugTriangle(c1[1], c1[2], c1[3], c2[1], c2[2], c2[3], c3[1], c3[2], c3[3], r, g, b, 1, false)
end

--- Draw a triangle (for debugging purpose)
---@param p1 table first point position {x, y, z}
---@param p2 table second point position {x, y, z}
---@param r number r
---@param g number g
---@param b number b
function Utility.drawDebugLine(p1, p2, r, g, b)
    drawDebugLine(p1[1], p1[2], p1[3], r, g, b, p2[1], p2[2], p2[3], r, g, b)
end

--- Render an AnimCurve (for debugging purpose)
---@param x number x position
---@param y number y position
---@param w number width
---@param h number height
---@param curve table AnimCurve object
---@param numPointsToShow? integer number of points to render
function Utility.renderAnimCurve(x, y, w, h, curve, numPointsToShow)
    local graph = curve.debugGraph
    local numPoints = numPointsToShow or #curve.keyframes
    local minTime = 0
    local maxTime = curve.maxTime
    if graph == nil then
        if numPointsToShow == nil then
            graph = Graph:new(numPoints, x, y, w, h, 0, 0.0001, true, "", Graph.STYLE_LINES)
            graph:setColor(1, 0, 0, 1)
            for i, kf in ipairs(curve.keyframes) do
                local v = curve:get(kf.time)
                graph:setValue(i, v)
                graph:setXPosition(i, (kf.time - minTime) / (maxTime - minTime))
                graph.maxValue = math.max(graph.maxValue, v)
            end
        else
            graph = Graph:new(numPoints + 1, x, y, w, h, 0, 0.0001, true, "", Graph.STYLE_LINES)
            graph:setColor(1, 0, 0, 1)
            for s = 1, numPoints + 1 do
                local i = s - 1
                local v = curve:get(minTime + (maxTime - minTime) * (i / numPoints))
                graph:setValue(s, v)
                graph.maxValue = math.max(graph.maxValue, v)
            end
        end
        curve.debugGraph = graph
    end
    graph:draw()
end

--- Get the loading speed meter object
---@return LoadingSpeedMeter loadingSpeedMeter
function Utility.getVehicleLoadingSpeedMeter()
    if Utility.loadingSpeedMeter == nil then
        ---@class LoadingSpeedMeter
        Utility.loadingSpeedMeter = {}
        Utility.loadingSpeedMeter.vehicles = {}
        Utility.loadingSpeedMeter.filters = {}
        --- Add a new filter
        ---@param filterFunction function | 'function(vehicleData) return true, "meter name" end'
        Utility.loadingSpeedMeter.addFilter = function(filterFunction)
            table.insert(Utility.loadingSpeedMeter.filters, filterFunction)
        end
        Utility.overwrittenFunction(
            Vehicle,
            "load",
            function(self, superFunc, vehicleData, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
                local smEnabled = false
                local smName = ""
                for _, filter in ipairs(Utility.loadingSpeedMeter.filters) do
                    smEnabled, smName = filter(vehicleData)
                    if smEnabled then
                        break
                    end
                end

                if smEnabled then
                    Utility.loadingSpeedMeter.vehicles[self] = {}
                    Utility.loadingSpeedMeter.vehicles[self].smName = smName
                    Utility.loadingSpeedMeter.vehicles[self].totalStartTime = getTimeSec()
                end

                local state = superFunc(self, vehicleData, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)

                if smEnabled then
                    Utility.loadingSpeedMeter.vehicles[self].totalTime = getTimeSec() - Utility.loadingSpeedMeter.vehicles[self].totalStartTime
                    print(string.format("[%s] Pre   time: %.4f ms", Utility.loadingSpeedMeter.vehicles[self].smName, (Utility.loadingSpeedMeter.vehicles[self].preLoadTime or 0) * 1000))
                    print(string.format("[%s] Load  time: %.4f ms", Utility.loadingSpeedMeter.vehicles[self].smName, (Utility.loadingSpeedMeter.vehicles[self].loadTime or 0) * 1000))
                    print(string.format("[%s] Post  time: %.4f ms", Utility.loadingSpeedMeter.vehicles[self].smName, (Utility.loadingSpeedMeter.vehicles[self].postLoadTime or 0) * 1000))
                    print(string.format("[%s] Total time: %.4f ms", Utility.loadingSpeedMeter.vehicles[self].smName, (Utility.loadingSpeedMeter.vehicles[self].totalTime or 0) * 1000))
                    Utility.loadingSpeedMeter.vehicles[self] = nil
                end
                return state
            end
        )
        Utility.overwrittenStaticFunction(
            SpecializationUtil,
            "raiseEvent",
            function(superFunc, vehicle, eventName, ...)
                if Utility.loadingSpeedMeter.vehicles[vehicle] ~= nil then
                    if eventName == "onPreLoad" then
                        Utility.loadingSpeedMeter.vehicles[vehicle].preLoadStartTime = getTimeSec()
                        superFunc(vehicle, eventName, ...)
                        Utility.loadingSpeedMeter.vehicles[vehicle].preLoadTime = getTimeSec() - Utility.loadingSpeedMeter.vehicles[vehicle].preLoadStartTime
                    end
                    if eventName == "onLoad" then
                        Utility.loadingSpeedMeter.vehicles[vehicle].loadStartTime = getTimeSec()
                        superFunc(vehicle, eventName, ...)
                        Utility.loadingSpeedMeter.vehicles[vehicle].loadTime = getTimeSec() - Utility.loadingSpeedMeter.vehicles[vehicle].loadStartTime
                    end
                    if eventName == "onPostLoad" then
                        Utility.loadingSpeedMeter.vehicles[vehicle].postLoadStartTime = getTimeSec()
                        superFunc(vehicle, eventName, ...)
                        Utility.loadingSpeedMeter.vehicles[vehicle].postLoadTime = getTimeSec() - Utility.loadingSpeedMeter.vehicles[vehicle].postLoadStartTime
                    end
                else
                    superFunc(vehicle, eventName, ...)
                end
            end
        )
    end
    return Utility.loadingSpeedMeter
end
