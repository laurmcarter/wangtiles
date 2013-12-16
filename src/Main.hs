{-# LANGUAGE OverloadedStrings #-}

import Config.Render
import Config.Render.Wang
import Config.TileSet
import Config.TileSet.Neighborhood
import Config.TileSet.Wang
import Data.Grid
import Data.Points
import Data.TileMap
import Display
import Display.Neighborhood
import Display.Wang
import Texture
import Tile
import Tile.Neighborhood
import Tile.Wang
import Util

import Data.List ((\\))
import qualified Data.Text as T
import System.Environment
import System.Exit
import Text.Show.Pretty

import Graphics.Gloss

-- TODO: * support layers of texture rendering
--       * improve efficiency/memory usage for large grids

parseArgs :: IO (Size Int)
parseArgs = do
  as <- getArgs
  case as of
    [c,r] -> return $ mkSize (read c) (read r)
    _       -> usage >> exitFailure

usage :: IO ()
usage = do
  putStrLn "Usage:"
  putStrLn $ "  ./wangtiles <# cols> <# rows>"

main :: IO ()
main = do
  sz <- parseArgs
  tss <- loadTileSets "data/tilesets.conf"

  blob  <- loadNeighborhoodTextureSet tss "blob"  neighborhood8
  fence <- loadNeighborhoodTextureSet tss "fence" neighborhood4
  rtm <- io' $ randomTileMap (0,1) sz
  tm1 <- io' $ neighborhoodTileMapByIndex blob  0 rtm
  tm2 <- io' $ neighborhoodTileMapByIndex fence 1 rtm
  let sz' = mkSize 10 5
  putStrLn $ ppTileMap neighTM
  displayTileMap rc blob sz' neighTM
  -- displayLayers rc sz (textureSize blob)
  --   $ map (uncurry $ renderTileMap rc) [(blob,tm1),(fence,tm2)]

  -- grass <- loadWangTextureSet wrc tss "grass" wangTiles2x2
  -- let tm = mkEmptyTileMap sz
  -- tm3 <- io' $ wangTileMap grass tm
  -- displayTileMap rc grass tm3
  where
  rc = defaultRenderConfig { windowBackground = black }
  wrc = defaultWangRenderConfig { wRenderConfig = rc }

