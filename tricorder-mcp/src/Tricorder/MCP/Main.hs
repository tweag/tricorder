module Tricorder.MCP.Main (main) where

import Data.Version (showVersion)
import MCP.Server
    ( McpServerHandlers (..)
    , McpServerInfo (..)
    , noHandlers
    , runMcpServerStdio
    )
import MCP.Server.Derive (deriveToolHandlerWithDescription)

import Paths_tricorder_mcp (version)
import Tricorder.MCP.Tools (Tool, handleTool, toolDescriptions)


main :: IO ()
main = runMcpServerStdio serverInfo handlers


handlers :: McpServerHandlers
handlers =
    noHandlers
        { tools = Just $(deriveToolHandlerWithDescription ''Tool 'handleTool toolDescriptions)
        }


serverInfo :: McpServerInfo
serverInfo =
    McpServerInfo
        { serverName = "Tricorder MCP Server"
        , serverVersion = toText (showVersion version)
        , serverInstructions = "A server to manage and use Tricorder for development purposes."
        }
