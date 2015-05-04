
module Dataset (
  calcDatasetItem,
  calcDataset
  ) where

import Data.Binary.Put
import qualified Crypto.Hash.SHA3 as SHA3
import Constants
import qualified Data.ByteString as B
import qualified Data.ByteString.Lazy as BL
import Data.Bits
import qualified Data.Vector as V
import Data.Word

import Cache
import Util

--import Debug.Trace

calcDatasetItem::Cache->Word32->B.ByteString
calcDatasetItem cache i =
  SHA3.hash 512 $ repair $ fst $ iterate (cacheFunc cache i) (shatter mixInit, 0 ) !! datasetParents
   where mixInit = SHA3.hash 512 $
                       BL.toStrict (runPut (putWord32le i) `BL.append` BL.replicate 60 0)  `xorBS`
                       (cache V.! (fromIntegral i `mod` n))
         n = V.length cache

cacheFunc :: V.Vector B.ByteString -> Word32 -> ([Word32], Word32 ) -> ([Word32], Word32)
cacheFunc cache i (mix, j) =
  (zipWith fnv mixLst mixWithLst, j+1)
  where mixLst = mix
        mixWithLst = (shatter $ cache V.! fromIntegral ( cacheIndex  `mod` n))
        cacheIndex = fnv (fromIntegral i `xor` j) (mixLst !! fromIntegral (j `mod` r))
        r = fromInteger $ hashBytes `div` wordBytes
        n = fromIntegral $ V.length cache

calcDataset::Word32->Cache->V.Vector B.ByteString
calcDataset size cache =
  V.fromList $ map (calcDatasetItem cache)
                   [0..(size-1) `div` fromInteger hashBytes]
