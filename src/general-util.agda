module general-util where

open import lib
open import functions

get-file-contents : (filename : string) → IO (maybe string)
get-file-contents e = 
  doesFileExist e >>= λ b → 
     if b then
      (readFiniteFile e >>= λ s → return (just s))
     else
      return nothing

maybe-else : ∀{ℓ}{A B : Set ℓ} → B → (A → B) → maybe A → B
maybe-else y f (just x) = f x
maybe-else y f nothing = y

trie-lookupd : ∀ {A : Set} → trie A → string → A → A
trie-lookupd t s d with trie-lookup t s
trie-lookupd t s d | nothing = d
trie-lookupd t s d | just x = x

trie-lookup-else : ∀{A : Set} → A → trie A → string → A
trie-lookup-else d t s = trie-lookupd t s d

trie-single : ∀{A : Set} → string → A → trie A
trie-single s x = trie-insert empty-trie s x

trie-any : ∀{A : Set} → (A → 𝔹) → trie A  → 𝔹
trie-cal-any : ∀{A : Set} → (A → 𝔹) → cal (trie A)  → 𝔹
trie-any f (Node odata ts) = maybe-else (trie-cal-any f ts) f odata
trie-cal-any f [] = ff
trie-cal-any f ((c , t) :: cs) = trie-any f t || trie-cal-any f cs 

trie-lookup𝕃 : ∀ {A : Set} → trie (𝕃 A) → string → 𝕃 A
trie-lookup𝕃 t s = trie-lookupd t s []

trie-lookup𝕃2 : ∀ {A : Set} → trie (string × 𝕃 A) → string → string × 𝕃 A
trie-lookup𝕃2 t s = trie-lookupd t s ("[nomod]" , [])

trie-lookup-string : trie string → string → string
trie-lookup-string t s = trie-lookupd t s "[not-found]"

trie-insert-append : ∀ {A : Set} → trie (𝕃 A) → string → A → trie (𝕃 A)
trie-insert-append t s a = trie-insert t s (a :: (trie-lookup𝕃 t s))

trie-insert-append2 : ∀ {A : Set} → trie (string × 𝕃 A) → string → string → A → trie (string × 𝕃 A)
trie-insert-append2 t s mn a = trie-insert t s (mn , (a :: snd (trie-lookup𝕃2 t s)))

trie-fill : ∀{A : Set} → trie A → 𝕃 (string × A) → trie A
trie-fill t ((s , a) :: vs) = trie-fill (trie-insert t s a) vs
trie-fill t [] = t

string-split-h : 𝕃 char → char → 𝕃 char → 𝕃 string → 𝕃 string
string-split-h [] delim str-build out = reverse ((𝕃char-to-string (reverse str-build)) :: out)
string-split-h (c :: cs) delim str-build out with (c =char delim)
... | tt = string-split-h cs delim [] ((𝕃char-to-string (reverse str-build)) :: out)
... | ff = string-split-h cs delim (c :: str-build) out

string-split : string → char → 𝕃 string
string-split str delim = string-split-h (string-to-𝕃char str) delim [] []

{-
This is needed for Windows. Depending on your operating system, this
may need to be either 2047 or 8191 (they are so close, however, that
this will only cause a problem if a string is ouput with between 8188 and 8191 characters.
On Windows, the output string is sent in "chunks" of 2047 characters.
However, "chunks" don't appear to get sent unless they have at least
2047 characters. This causes the n last characters in each output string
to get cut off, where n = (length string) % 2047.
To read more: https://support.microsoft.com/en-us/help/830473/command-prompt-cmd--exe-command-line-string-limitation
-}
chunk-size = 2047

get-ws-to-add : string → ℕ
get-ws-to-add s with string-length s
...| l = chunk-size ∸ (snd (l ÷ chunk-size))

get-n-ws-h : ℕ → 𝕃 char → 𝕃 char
get-n-ws-h 0 lc = lc
get-n-ws-h (suc n) lc = get-n-ws-h n (' ' :: lc)

get-n-ws : ℕ → string
get-n-ws n = 𝕃char-to-string (get-n-ws-h n [])

add-windows-ws : string → string
add-windows-ws s = (get-n-ws (get-ws-to-add s)) ^ s ^ " "

add-windows-ws-full : IO ⊤
add-windows-ws-full = putStr (get-n-ws chunk-size)

putStrLn : string → IO ⊤
putStrLn str = putStr (add-windows-ws (str ^ "\n"))

undo-escape-string-h : 𝕃 char → 𝕃 char → 𝕃 char
undo-escape-string-h ('\\' :: 'n' :: rest) so-far = undo-escape-string-h rest ('\n' :: so-far)
undo-escape-string-h ('\\' :: '\"' :: rest) so-far = undo-escape-string-h rest ('\"' :: so-far)
undo-escape-string-h (c :: rest) so-far = undo-escape-string-h rest (c :: so-far)
undo-escape-string-h [] so-far = reverse so-far

undo-escape-string : string → string
undo-escape-string str = 𝕃char-to-string (undo-escape-string-h (string-to-𝕃char str) [])

-- functions.agda
curry : ∀{ℓ₁ ℓ₂ ℓ₃}{A : Set ℓ₁}{B : Set ℓ₂}{C : Set ℓ₃}
        → (A × B → C) → A → B → C
curry f a b = f (a , b)

uncurry : ∀{ℓ₁ ℓ₂ ℓ₃}{A : Set ℓ₁}{B : Set ℓ₂}{C : Set ℓ₃}
          → (f : A → B → C) → (p : A × B) → C
uncurry f (a , b) = f a b

infix 0 case_return_of_ case_of_

case_return_of_ :
  ∀ {ℓ₁ ℓ₂} {A : Set ℓ₁}
  (x : A) (B : A → Set ℓ₂) → ((x : A) → B x) → B x
case x return B of f = f x

case_of_ : ∀ {a b} {A : Set a} {B : Set b} → A → (A → B) → B
case x of f = case_return_of_ x _ f

flip : ∀ {a b c} {A : Set a} {B : Set b} {C : Set c}
       → (A → B → C) → (B → A → C)
flip f = λ b a → f a b

-- list.agda

take : ∀{ℓ}{A : Set ℓ} → ℕ → 𝕃 A → 𝕃 A
take 0 l = []
take (suc n) (x :: l) = x :: (take n l)
take (suc n) [] = []

zip-with : ∀{ℓ₁ ℓ₂ ℓ₃}{A : Set ℓ₁}{B : Set ℓ₂}{C : Set ℓ₃}
           → (A → B → C) → 𝕃 A → 𝕃 B → 𝕃 C
zip-with f xs ys = map (uncurry f) (zip xs ys)

-- error.agda
err-guard : 𝔹 → string → error-t ⊤
err-guard tt msg = yes-error msg
err-guard ff _   = no-error triv

-- Some file writing functions
data IOMode : Set where
  ReadMode : IOMode
  WriteMode : IOMode
  AppendMode : IOMode
  ReadWriteMode : IOMode

postulate
  Handle : Set
  -- IOMode : Set
  openFile : string → IOMode -> IO Handle
  closeFile : Handle -> IO ⊤
  hPutStr : Handle → string → IO ⊤

{-# COMPILED_TYPE Handle System.IO.Handle #-}
{-# COMPILED_DATA IOMode System.IO.IOMode System.IO.ReadMode System.IO.WriteMode System.IO.AppendMode System.IO.ReadWriteMode #-}
{-# COMPILED openFile (\fp -> (\mode -> do outh <- System.IO.openFile (Data.Text.unpack fp) mode; System.IO.hSetNewlineMode outh System.IO.noNewlineTranslation; System.IO.hSetEncoding outh System.IO.utf8; return outh)) #-}
{-# COMPILED closeFile System.IO.hClose #-}
{-# COMPILED hPutStr (\ hdl -> (\ s -> Data.Text.IO.hPutStr hdl s)) #-}

clearFile : string → IO ⊤
clearFile fp = openFile fp WriteMode >>= λ hdl → hPutStr hdl "" >> closeFile hdl

infixl 1 _>>≠_

_>>≠_  : ∀{A B : Set} → IO A → IO B → IO A
(io₁ >>≠ io₂) = io₁ >>= λ result → io₂ >> return result

withFile : {A : Set} → string → IOMode → (Handle → IO A) → IO A
withFile fp mode f = openFile fp mode >>= λ hdl → f hdl >>≠ closeFile hdl

-- Coordinated Universal Time
infix 15 _utc-after_ _utc-before_

postulate
  UTC : Set
  getCurrentTime : IO UTC
  _utc-after_ : UTC → UTC → 𝔹
  _utc-before_ : UTC → UTC → 𝔹
  utcToString : UTC → string
  getModificationTime : string → IO UTC

{-# IMPORT Data.Time.Clock #-}
{-# IMPORT Data.Time.Calendar #-}
{-# COMPILED_TYPE UTC Data.Time.Clock.UTCTime #-}
{-# COMPILED getCurrentTime Data.Time.Clock.getCurrentTime #-}
{-# COMPILED _utc-after_ (>) #-}
{-# COMPILED _utc-before_ (<) #-}
{-# COMPILED utcToString (\ t -> case t of Data.Time.Clock.UTCTime day time -> Data.Text.pack ((Data.Time.Calendar.showGregorian day) ++ ", " ++ (show time))) #-}
{-# COMPILED getModificationTime (\ s -> System.Directory.getModificationTime (Data.Text.unpack s)) #-}

-- string binary tree, for more efficient I/O printing than concatenation
data streeng : Set where
  _⊹⊹_ : streeng → streeng → streeng
  [[_]] : string → streeng

infixl 9 _⊹⊹_
infix 9 [[_]]

[[]] : streeng
[[]] = [[ "" ]]

streeng-to-string : streeng → string
streeng-to-string = flip h "" where
  h : streeng → string → string
  h (s₁ ⊹⊹ s₂) = h s₁ ∘ h s₂
  h [[ s ]] acc = s ^ acc

putStreeng : streeng → IO ⊤
-- putStreeng = putStr ∘ streeng-to-string
putStreeng s = h s (return triv) where
  h : streeng → IO ⊤ → IO ⊤
  h (s₁ ⊹⊹ s₂) io = h s₁ (h s₂ io)
  h [[ s ]] io = putStr s >> io

putStreengLn : streeng → IO ⊤
putStreengLn s = putStreeng s >> putStr "\n" >> add-windows-ws-full

hPutStreeng : Handle → streeng → IO ⊤
hPutStreeng outh s = h s (return triv) outh where
  h : streeng → IO ⊤ → Handle → IO ⊤
  h (s₁ ⊹⊹ s₂) io outh = h s₁ (h s₂ io outh) outh
  h [[ s ]] io outh = hPutStr outh s >> io

writeStreengToFile : (filepath : string) → streeng → IO ⊤
writeStreengToFile fp s = clearFile fp >> openFile fp AppendMode >>= λ hdl → hPutStreeng hdl s >> closeFile hdl

stringset-singleton : string → stringset
stringset-singleton x = stringset-insert empty-stringset x

