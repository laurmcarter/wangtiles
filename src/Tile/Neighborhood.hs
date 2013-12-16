
module Tile.Neighborhood where

import Display
import Tile
import Util

import Control.Applicative
import Control.Monad
import Data.List  (transpose)
import Data.Maybe (fromMaybe)

import Graphics.Gloss

-- Neighborhoods {{{

-- TODO: decode at compile time with TH
neighborhood4 :: TileSet Neighborhood
neighborhood4 = decodeNeighborhood4s
  [ [ [ "..." , "..." , "..." , "..." ]
    , [ ".o." , ".oo" , "ooo" , "oo." ]
    , [ ".o." , ".o." , ".o." , ".o." ]
    ] ---------------------------------
  , [ [ ".o." , ".o." , ".o." , ".o." ]
    , [ ".o." , ".oo" , "ooo" , "oo." ]
    , [ ".o." , ".o." , ".o." , ".o." ]
    ] ---------------------------------
  , [ [ ".o." , ".o." , ".o." , ".o." ]
    , [ ".o." , ".oo" , "ooo" , "oo." ]
    , [ "..." , "..." , "..." , "..." ]
    ] ---------------------------------
  , [ [ "..." , "..." , "..." , "..." ]
    , [ ".o." , ".oo" , "ooo" , "oo." ]
    , [ "..." , "..." , "..." , "..." ]
    ]
  ]

neighborhood8 :: TileSet Neighborhood
neighborhood8 = decodeNeighborhood8s
  [ [ [ "..." , "..." , "..." , "..." , "..." , "..." , "..." , "ooo" , "ooo" , "ooo" ]
    , [ ".o." , ".oo" , "ooo" , "oo." , ".oo" , "ooo" , "oo." , "ooo" , "ooo" , "ooo" ]
    , [ ".o." , ".oo" , "ooo" , "oo." , ".o." , ".o." , ".o." , "oo." , ".o." , ".oo" ]
    ] ---------------------------------------------------------------------------------
  , [ [ ".o." , ".oo" , "ooo" , "oo." , ".o." , "..." , ".o." , "oo." , ".o." , ".oo" ]
    , [ ".o." , ".oo" , "ooo" , "oo." , ".oo" , ".o." , "oo." , "ooo" , "ooo" , "ooo" ]
    , [ ".o." , ".oo" , "ooo" , "oo." , ".o." , "..." , ".o." , "oo." , ".o." , ".oo" ]
    ] ---------------------------------------------------------------------------------
  , [ [ ".o." , ".oo" , "ooo" , "oo." , ".o." , ".o." , ".o." , "oo." , ".o." , ".oo" ]
    , [ ".o." , ".oo" , "ooo" , "oo." , ".oo" , "ooo" , "oo." , "ooo" , "ooo" , "ooo" ]
    , [ "..." , "..." , "..." , "..." , "..." , "..." , "..." , "ooo" , "ooo" , "ooo" ]
    ] ---------------------------------------------------------------------------------
  , [   {---} [ "..." , "..." , "..." , "..." , "oo." , ".oo" , "..." , "oo." , ".oo" ]
    ,   {---} [ ".oo" , "ooo" , "oo." , "ooo" , "oo." , ".oo" , "ooo" , "ooo" , "ooo" ]
    ,   {---} [ "..." , "..." , "..." , "oo." , ".o." , ".o." , ".oo" , ".o." , ".o." ]
    ] ---------------------------------------------------------------------------------
  , [   {---}   {---} [ "oo." , ".oo" , ".o." , ".oo" , "oo." , ".o." , ".o." , ".o." ]
    ,   {---}   {---} [ "ooo" , "ooo" , ".oo" , "ooo" , "ooo" , "oo." , "ooo" , "ooo" ]
    ,   {---}   {---} [ ".oo" , "oo." , ".oo" , "..." , "..." , "oo." , "oo." , ".oo" ]
    ]
  ]

-- }}}

-- Neighborhood {{{

data Neighborhood = Neighborhood
  { nNW :: Neighbor
  , nN  :: Neighbor
  , nNE :: Neighbor
  , nE  :: Neighbor
  , nSE :: Neighbor
  , nS  :: Neighbor
  , nSW :: Neighbor
  , nW  :: Neighbor
  } deriving (Show)

type Neighbor = Maybe Bool

instance Eq Neighborhood where
  x == y = eq nNW && eq nN && eq nNE
        && eq nW           && eq nE
        && eq nSW && eq nS && eq nSE
    where
    eq f = fromMaybe True $ (==) <$> f x <*> f y

same :: Neighbor
same = Just True

diff :: Neighbor
diff = Just False

wild :: Neighbor
wild = Nothing

-- }}}

-- NeighborhoodConstraint {{{

tmMatches :: NeighborhoodTileSet -> TileMap -> Coord
  -> NeighborhoodTileSet
tmMatches ts tm c = matchingNeighborhoods ts $ tmNeighborhood tm c

matchingNeighborhoods :: NeighborhoodTileSet
  -> Neighborhood -> NeighborhoodTileSet
matchingNeighborhoods ts n = tsFilter ((n ==) . snd) ts

tmNeighborhood :: TileMap -> Coord -> Neighborhood
tmNeighborhood tm = mkNeighborhood . tmSurrounding tm

mkNeighborhood :: Eq a => Surrounding a -> Neighborhood
mkNeighborhood s = Neighborhood
  { nNW = (center ==) <$> corner sNW sN sW
  , nN  = (center ==) <$> edge   sN
  , nNE = (center ==) <$> corner sNE sN sE
  , nE  = (center ==) <$> edge   sE
  , nSE = (center ==) <$> corner sSE sS sE
  , nS  = (center ==) <$> edge   sS
  , nSW = (center ==) <$> corner sSW sS sW
  , nW  = (center ==) <$> edge   sW
  }
  where
  center = sC s
  edge e = e s `mplus` return center
  corner c e1 e2 = c s `mplus` e1 s `mplus` e2 s `mplus` return center

-- }}}

-- NeighborhoodTileSet {{{

type NeighborhoodTileSet = TileSet (Picture,Neighborhood)

neighborhoodAt :: NeighborhoodTileSet -> TileIndex -> Neighborhood
neighborhoodAt ts i = snd $ neighborhoodTexture ts i

neighborhoodTexture :: NeighborhoodTileSet -> TileIndex
  -> (Picture,Neighborhood)
neighborhoodTexture = tsIndex

-- }}}

-- Decode {{{

type EncodedNeighborhoods = [[[String]]]

decodeNeighborhood4s , decodeNeighborhood8s :: 
  EncodedNeighborhoods -> TileSet Neighborhood
decodeNeighborhood4s = mkNeighborhoods . decodeNeighborhoods True
decodeNeighborhood8s = mkNeighborhoods . decodeNeighborhoods False

decodeNeighborhoods :: Bool -> EncodedNeighborhoods -> [Neighborhood]
decodeNeighborhoods isN4 =
    map decodeN
  . concat
  . map (map concat . transpose)
  where
  decodeN [nw,n,ne,w,_,e,sw,s,se] = Neighborhood
    { nNW = decodeC nw
    , nN  = decodeE n
    , nNE = decodeC ne
    , nE  = decodeE e
    , nSE = decodeC se
    , nS  = decodeE s
    , nSW = decodeC sw
    , nW  = decodeE w
    }
  decodeN s = error $ "cannot decode String to Neighborhood: " ++ show s
  decodeE c = case c of
    '.' -> diff
    'o' -> same
    '*' -> wild
    _   -> err c
  decodeC c = if isN4 then wild else case c of
    '.' -> diff
    'o' -> same
    '*' -> wild
    _   -> err c
  err c = error $ "cannot decode Char to Neighborhood: " ++ show c

mkNeighborhoods :: [Neighborhood] -> TileSet Neighborhood
mkNeighborhoods = tsMap relax . tsFromList . zip [0..]
  where
  relax n = n
    { nNW = relaxC (nNW n) (nN n) (nW n)
    , nNE = relaxC (nNE n) (nN n) (nE n)
    , nSW = relaxC (nSW n) (nS n) (nW n)
    , nSE = relaxC (nSE n) (nS n) (nE n)
    }
  relaxC c e1 e2
    | e1 == diff || e2 == diff
    = wild
    | otherwise
    = c

-- }}}

-- TileMap {{{

type NeighborhoodTextureSet = TextureSet Neighborhood

neighborhoodTileMapByIndex :: NeighborhoodTextureSet -> TileIndex
  -> TileMap -> Either Coord TileMap
neighborhoodTileMapByIndex ts ti tm = neighborhoodTileMap ts tm $ tmSubMapByValue ti tm

neighborhoodTileMap :: NeighborhoodTextureSet -> TileMap -> Coords -> Either Coord TileMap
neighborhoodTileMap ts tm = csGenerateTileMapA fn
  where
  fn c = maybe (Left c) return $ tmMatch (textureSet ts) tm c

tmMatch :: NeighborhoodTileSet -> TileMap -> Coord
  -> Maybe TileIndex
tmMatch ts tm c = fmap fst $ tsGetSingle $ tmMatches ts tm c

-- }}}

-- Pretty Printing {{{

ppNP :: Neighborhood -> String
ppNP n = ppRows
  [ [ shw $ nNW n , shw $ nN  n , shw $ nNE n ]
  , [ shw $ nW  n ,     "."     , shw $ nE  n ]
  , [ shw $ nSW n , shw $ nS  n , shw $ nSE n ]
  ]
  where
  shw Nothing  = "*"
  shw (Just p) = show p

-- }}}
