(define-module (babweb lib utilities) 
 #:use-module (srfi srfi-19) ;; date time
 #:use-module (srfi srfi-1)  ;;list searching; delete-duplicates in list 
 #:use-module (srfi srfi-9)  ;;records
 #:use-module (ice-9 rdelim)
 #:use-module (ice-9 i18n)   ;; internationalization
 #:use-module (ice-9 popen)
 #:use-module (ice-9 regex) ;;list-matches
 #:use-module (ice-9 receive)	     
 #:use-module (ice-9 string-fun)  ;;string-replace-substring
 #:use-module (ice-9 pretty-print)
 #:use-module (json)
 #:use-module (rnrs bytevectors )
;; #:use-module (rnrs io ports #:select ())
 #:use-module (ice-9 textual-ports)
 #:use-module (babweb lib env)
 #:use-module (ice-9 ftw);;scandir
 #:export (get-rand-file-name
	   add-two-lists
	   chunk-a-tweet
	   get-counter
	   set-counter
	   find-by-id
	   get-all-excerpts-alist
	   get-all-hashtags-string
	   get-nonce
	   get-next-val-param
	   get-image-file-name
	   get-expired
	   encrypt-alist
	   decrypt-alist
	   envs-report
	   lst-to-query-string
	   call-command-with-output-to-string))


(define (add-two-lists lst base id)
  ;;lst: new elements to be added; monitor this for null
  ;;base: base list i.e. the db
  ;;id: starting id (a number)
  (if (null? (cdr lst))
      (let*(
	    (a  (assoc-set! (car lst) "id" id))	   
	    (dummy  (set! base (cons a base) )))
	base)
      (let*((a  (assoc-set! (car lst) "id" id))
	    (dummy  (set! base (cons a base) ))
	    (dummy (set! id (+ id 1))))
	(add-two-lists (cdr lst) base id))))


(define nonce-chars (list->vector (string->list "ABCDEFGHIJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz123456789")))

(define (get-nonce n s)
  "n is the length of the nonce
   s is the nonce itself (a string)
   therefore to use: (get-nonce 20 "")"
 (if (= n (string-length s))
     s
     (begin
       (set! s (string-append s (string (vector-ref nonce-chars (random 58 (seed->random-state (number->string (time-nanosecond (current-time)))))) )))
       (get-nonce n s))))
  	 
(define (get-rand-file-name pre suff)
  (string-append pre "-" (number->string (random 10000000000000000000000)) "." suff))

(define (get-counter)
  ;;counter is the last tweeted id
  ;;start with (+ counter 1) for this session
  (let* (
	 (p  (open-input-file (string-append *data-dir* "/last-posted.json")))
	 (a (json-string->scm (get-string-all p)))
	 (dummy (close-port p))
	 (b (assoc-ref a "last-posted-id")))
    b))

(define (set-counter x)
(let* ((p  (open-output-file (string-append *data-dir* "/last-posted.json")))
	 (a (scm->json-string `(("last-posted-id" . ,x))))
	 (dummy (put-string p a)))
  (close-port p)))

(define (my-last lst)
  (if (null? (cdr lst))
      (car lst)
      (my-last (cdr lst))))

(define (get-next-val-param lst param val)
  ;;get the max value for a parameter e.g. id so
  ;;the next id can be assigned
  ;;assume a string in a json so convert to integer
  ;;usage (get-max-val-param lst param 0)
  (if (null? (cdr lst))
      (begin
	(set! val (max (string->number (assoc-ref (car lst) param)) val))
	(number->string (+ val 1)))
      (begin
	(set! val (max (string->number (assoc-ref (car lst) param)) val))
      (get-next-val-param (cdr lst) param val))))


(define (get-tweet-chunks txt lst size n counter)
  ;;txt whole tweet
  ;;size: # chars per chunk
  ;;number of chunks
  ;; (get-tweet-chunks "fjskdjk" '() 240 4 1)  start counter at 1 i.e. the first tweet
  (if (= counter n)
      (let*( (tweet (if (= n 1) txt
			(string-append "@eddiebbot " (number->string counter) "/" (number->string n) " " txt))) )	
	  (reverse (cons tweet lst)))
      (let*((tweet1  (substring txt 0 size))
	    (last-space-index (string-rindex tweet1 #\space))
	    
	    (tweet2  (if  (= counter 1)
			 (string-append (number->string counter) "/" (number->string n) " " (substring tweet1 0 last-space-index))
			 (string-append  "@eddiebbot " (number->string counter) "/" (number->string n) " " (substring tweet1 0 last-space-index))
			 ))	    
	    (rest-txt  (substring txt (+ last-space-index 1) (string-length txt)))
	    (dummy (set! lst (cons tweet2 lst) ))
	    (dummy (set! counter (+ counter 1)))
	)  
	(get-tweet-chunks rest-txt lst size n counter))
  ))

(define (chunk-a-tweet text size)
  ;;text: the whole tweet
  ;;size: size of chunks e.g. 280 for twitter
  ;;Split a tweet >280 characters into multiple tweets and number 1/4, 2/4 etc.
  ;;Since the number will take up 4 characters, you have 280 - 4 =276 characters per tweet
  ;;return a list of the individual, numbered tweets in reverse order for tweeting
  (let*((nchars (string-length text))
	(size-mod (- size 4))
	(ntweets (ceiling (/ nchars size-mod)))
	)
  (get-tweet-chunks text '() size-mod ntweets 1) ))

(define (get-all-excerpts-alist)
  (let* ((p  (open-input-file (string-append *data-dir* "/db.json")))
	 (a (vector->list (json-string->scm (get-string-all p)))))	
     a))

(define (add-hash-recurse lst newlst)
  (if (null? (cdr lst))
      (begin
	(set! newlst (cons  (string-append "#" (car lst)) newlst))
	newlst)
      (begin
	(set! newlst (cons  (string-append "#" (car lst)) newlst))
	(add-hash-recurse (cdr lst) newlst))))

(define (get-all-hashtags-string)
  ;;hashtags stored with #
  (let* ((p  (open-input-file (string-append *data-dir* "/hashtags.json")))
	 (a (vector->list (assoc-ref (json-string->scm (get-string-all p)) "hashtags"))))	
     (string-join (add-hash-recurse a '()))))


(define (find-by-id lst id)
  ;;find an entity by id
  ;;return whole entity
  (if (null? (cdr lst))
      (if (= (assoc-ref (car lst) "id") id) (car lst) #f)
      (if (= (assoc-ref (car lst) "id") id)
	   (car lst)
	  (find-by-id (cdr lst) id))))

(define (get-random-image dir)
  ;;directory is (string-append working-dir "/random/")
  (let* (;;(dir (string-append *working-dir* "/random/"))
	 (all-files (list->vector (cddr (scandir dir)) )))
   (vector-ref all-files (random (vector-length all-files) (seed->random-state (number->string (time-nanosecond (current-time)))))) ) )


(define (get-image-file-name directive)
  (cond ((string=? directive "none") (#f))
	((string=? directive "random")(string-append *data-dir* "/random/" (get-random-image (string-append *data-dir* "/random/"))) )	
	(else (string-append *data-dir* "/specific/" directive))
     ))

(define (get-expired expires-in)
  ;;expires-in: how many seconds before expiration; an integer
  (+ (time-second (current-time))   expires-in))


(define (encrypt-alist alist fname)
  (let* ((json-string (scm->json-string alist))
	 (out-file (get-rand-file-name "f" "txt"))
	 (p  (open-output-file out-file))
	 (command (string-append "gpg --output " fname " --encrypt --recipient " *gpg-key* " " out-file)))
  (begin
    (put-string p json-string)
    (force-output p)
    (close-port p)
    (system command)
    (delete-file out-file)
    )))

(define (decrypt-alist fname)
  (let* ((out-file (get-rand-file-name "f" "txt"))
	 (command  (string-append "gpg --output " out-file " --decrypt " fname))
	 (_ (system command))
	 (p  (open-input-file  out-file))
	 (a (get-string-all p))
	 (_ (delete-file out-file)))
    (json-string->scm  a)))
  
(define (lst-to-query-string lst s)
  ;;start with (lst-to-query-string lst "?")
  (if (null? (cdr lst))
      (begin 
	(set! s (string-append s (caar lst) "=" (cadar lst)))
	s)
      (begin
	(set! s (string-append s (caar lst) "=" (cadar lst) "&"))
	(lst-to-query-string (cdr lst) s))))

(define (envs-report file-name)
  (let* ( (vals (decrypt-alist file-name))
	  (expired (assoc-ref vals "expired"))
	  (remaining (if expired (- expired (time-second (current-time))) #f))	 
	  )
    (begin
      (pretty-print  vals)
      (if remaining (pretty-print (string-append "remaining: " (number->string remaining ) "  [negative indicates expired]")))
      )))

(define (call-command-with-output-to-string cmd)
  ;;(import (ice-9 rdelim) (ice-9 popen) (rnrs io ports))
  ;;https://www.draketo.de/software/guile-capture-stdout-stderr.html
  (let* ((out-cons (pipe))
         (port (with-output-to-port (cdr out-cons)
                 (lambda() (open-input-pipe cmd))))
         (_ (setvbuf (car out-cons) 'block 
             (* 1024 1024 16)))
         (result (read-delimited "" port)))
    (close-port (cdr out-cons))
    (values
     result
     (read-delimited "" (car out-cons)))))
