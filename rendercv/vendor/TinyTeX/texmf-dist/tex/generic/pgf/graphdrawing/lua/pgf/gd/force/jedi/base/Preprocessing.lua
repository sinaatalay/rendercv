-- Copyright 2014 by Ida Bruhns
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information


--- This file holds functions to create lists of vertex pairs. All
-- functions return a Graph object containing the vertices of the
-- original graph and an edge between the vertices forming a pair
-- under the specified conditions. The lists can be precomputed to
-- enhance performance.

local PreprocessClass = {}

-- Imports
local declare = require "pgf.gd.interface.InterfaceToAlgorithms".declare
local Digraph = require "pgf.gd.model.Digraph"


-- Creates a graph object with an arc between all pairwise disjoint vertex
-- pairs and returns the arc table
--
-- @param vertices The vertices of the original graph
--
-- @return An arc table

function PreprocessClass.allPairs(vertices)
    local aP = Digraph.new{}
    for _, vertex in ipairs(vertices) do
        for _, vertex2 in ipairs(vertices) do
            if vertex ~= vertex2 then
                if not aP:contains(vertex) then
                    aP:add {vertex}
                end
                if not aP:contains(vertex2) then
                    aP:add {vertex2}
                end
                if not aP:arc(vertex, vertex2) and not aP:arc(vertex2, vertex) then
                    aP:connect(vertex, vertex2)
                end
            end
        end
    end
    return aP.arcs
end


-- Creates a graph object with an arc between all pairwise disjoint vertex
-- pairs that are connected by a shortest path of length n in the original
-- graph and returns the arc table
--
-- @param vertices The vertices of the original graph
-- @param arcs The arcs of the original graph
-- @param n The length of the shortest path we are looking for
--
-- @return An arc table

function PreprocessClass.overExactlyNPairs(vertices, arcs, n)
    local waste, p_full = PreprocessClass.overMaxNPairs(vertices, arcs, n)
    local waste, p_small = PreprocessClass.overMaxNPairs(vertices, arcs, n-1)
    for _, paar in ipairs(p_full.arcs) do
        if p_small:arc(paar.head, paar.tail) ~= nil or p_small:arc(paar.tail, paar.head) ~= nil then
            p_full:disconnect(paar.head, paar.tail)
            p_full:disconnect(paar.tail, paar.head)
        end
    end
    return p_full.arcs
end


-- Creates a graph object with an arc between all pairwise disjoint vertex
-- pairs that are connected by a shortest path of length n or shorter in the
-- original graph and returns the arc table
--
-- @param vertices The vertices of the original graph
-- @param arcs The arcs of the original graph
-- @param n The length of the shortest path we are looking for
--
-- @return An arc table

function PreprocessClass.overMaxNPairs(vertices, arcs, n)
    assert(n >= 0, 'n (value: ' .. n.. ') needs to be greater or equal 0')
    local p = Digraph.new{}
    local oneHop = Digraph.new{}
    if n> 0 then
        for _, arc in ipairs(arcs) do
            local vertex = arc.head
            local vertex2 = arc.tail
            if not p:contains(vertex) then
                p:add {vertex}
                oneHop:add {vertex}
            end
            if not p:contains(vertex2) then
                p:add {vertex2}
                oneHop:add {vertex2}
            end
            if p:arc(vertex, vertex2) == nil and p:arc(vertex2, vertex) == nil then
                p:connect(vertex, vertex2)
                oneHop:connect(vertex, vertex2)
            end
        end
    end

    n = n-1
    while n > 0 do
        for _, paar in ipairs(p.arcs) do
            for _, vertex in ipairs(vertices) do
                if paar.head ~= vertex and p:arc(paar.head, vertex) == nil  and  p:arc(vertex, paar.head) == nil and (oneHop:arc(paar.tail, vertex) ~= nil or oneHop:arc(vertex, paar.tail) ~= nil) then
                    p:connect(paar.head, vertex)
                end
            end
        end
        n = n-1
    end
    return p.arcs, p
end

return PreprocessClass
