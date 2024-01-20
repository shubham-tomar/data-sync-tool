{-# LANGUAGE OverloadedStrings #-}

module Main where

import Data.Conduit((.|))
import qualified Data.Conduit as Conduit
import qualified Data.Conduit.Combinators as Conduit
import Data.Conduit(ConduitT, await, yield)
import Data.ByteString(ByteString)
import Data.Attoparsec.ByteString
import Data.Aeson(Value, encode)
import Data.Aeson.Parser(json)
import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as LBS
import Data.Aeson
import Data.Aeson.KeyMap (insert)
import qualified Data.Aeson.KeyMap as KeyMap
import qualified Data.HashMap.Strict as HM
import Data.Scientific (toBoundedInteger, Scientific)
import Data.Text (Text, unpack)
import Control.Lens ((^?), ix)
import Data.Aeson.Lens (_String)
import qualified Text.Read as TR
import Debug.Trace (trace)
import qualified Data.List as L


boolList :: [Key]
boolList = ["col1", "col2", "col3"]

numberList :: [Key]
numberList = ["amount", "tax_amount", "net_amount"]

jsonValueParser :: Parser Value
jsonValueParser = do
  skipWhile (/= (toEnum $ fromEnum '{'))
  json

conduitJSONParser :: (Monad m, MonadFail m) => ConduitT ByteString Value m ()
conduitJSONParser =
    awaitNE >>= start
  where
    awaitNE =
        loop
      where
        loop = await >>= maybe (return BS.empty) check
        check bs
            | BS.null bs = loop
            | otherwise = return bs

    start bs
        | BS.null bs = return ()
        | otherwise = result (parse jsonValueParser bs)

    result (Fail _ _ err) = fail err
    result (Partial f) = await >>= maybe (pure ()) (result . f)
    result (Done rest x) = do
        yield x
        if BS.null rest
            then awaitNE >>= start
            else start rest

main :: IO ()
main = do
  Conduit.runConduitRes
    $ Conduit.stdin
    .| conduitJSONParser
    .| Conduit.map (jqTransformations transformBool boolList)
    .| Conduit.map (jqTransformations transformNumber numberList)
    .| Conduit.map (\r -> LBS.toStrict $ encode r <> "\n")
    .| Conduit.stdout
  return ()


jqTransformations :: (Key -> Object -> Value) -> [Key] -> Value -> Value
jqTransformations transformFunc colList val@(Object obj) =
  Object $ L.foldl' (\o col -> insert col (transformFunc col o) o) obj colList
jqTransformations func colList val = val

transformNumber :: Key -> Object -> Value
transformNumber col o =
    case o ^? ix col of
        Just (String s) -> case textToScientific s of
            Just n  -> Number n
            Nothing -> String s
        Just (Number n) -> Number n
        _               -> Null

transformBool :: Key -> Object -> Value
transformBool col o =
    case o ^? ix col of
        Just (String s) -> case textToBool s of
            Just b  -> Bool b
            Nothing -> String s
        Just (Bool b) -> Bool b
        _             -> Null

textToScientific :: Text -> Maybe Scientific
textToScientific s = TR.readMaybe (unpack s) :: Maybe Scientific

textToBool :: Text -> Maybe Bool
textToBool val = do
  case val of
    "True"  -> Just True
    "False" -> Just False
    "true"  -> Just True
    "false" -> Just False
    "1"     -> Just True
    "0"     -> Just False
    _       -> Nothing