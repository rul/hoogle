
module Recipe.Keyword(makeKeyword) where

import General.Base
import Text.HTML.TagSoup
import Recipe.Type
import Recipe.General


makeKeyword :: IO ()
makeKeyword = convertSrc noDeps [] "keyword" . translate =<< readFileUtf8' keywords


translate :: String -> String
translate src = unlines $ keywordPrefix ++ items
    where items = concatMap keywordFormat $ drop 1 $ partitions (~== "<a name>") $
                  takeWhile (~/= "<div class=printfooter>") $ parseTags src


keywordPrefix =
    ["-- Hoogle documentation, generated by Hoogle"
    ,"-- From http://www.haskell.org/haskellwiki/Keywords"
    ,"-- See Hoogle, http://www.haskell.org/hoogle/"
    ,""
    ,"-- | Haskell keywords, always available"
    ,"@url http://haskell.org/haskellwiki/Keywords"
    ,"@package keyword"
    ]


keywordFormat x = concat ["" : docs ++ ["@url #" ++ concatMap g n, "@entry keyword " ++ noUnderscore n] | n <- name]
    where
        noUnderscore "_" = "_"
        noUnderscore xs = map (\x -> if x == '_' then ' ' else x) xs

        name = words $ f $ fromAttrib "name" (head x)
        docs = zipWith (++) ("-- | " : repeat "--   ") $
               intercalate [""] $
               map (docFormat . takeWhile (~/= "<div class=editsection>")) $
               partitions isBlock x

        g x | isAlpha x || x `elem` "_-:" = [x]
            | otherwise = '.' : map toUpper (showHex (ord x) "")


        isBlock (TagOpen x _) = x `elem` ["p","pre"]
        isBlock _ = False

        f ('.':'2':'C':'_':xs) = ' ' : f xs
        f ('.':a:b:xs) = chr res : f xs
            where [(res,"")] = readHex [a,b]
        f (x:xs) = x : f xs
        f [] = []


docFormat :: [Tag String] -> [String]
docFormat (TagOpen "pre" _:xs) = ["<pre>"] ++ map (drop n) ys ++ ["</pre>"]
    where
        ys = lines $ innerText xs
        n = minimum $ map (length . takeWhile isSpace) ys

docFormat (TagOpen "p" _:xs) = g 0 [] $ words $ f xs
    where
        g n acc [] = [unwords $ reverse acc | acc /= []]
        g n acc (x:xs) | nx+1+n > 70 = g n acc [] ++ g nx [x] xs
                       | otherwise = g (n+nx+1) (x:acc) xs
            where nx = length x

        f (TagOpen "code" _:xs) = "<tt>" ++ innerText a ++ "</tt>" ++ f (drop 1 b)
            where (a,b) = break (~== "</code>") xs
        f (x:xs) = h x ++ f xs
        f [] = []

        h (TagText x) = unwords (lines x)
        h _ = ""
