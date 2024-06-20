(define-module (ebbot utilities) 
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
 #:use-module (rnrs bytevectors)
 #:use-module (ice-9 textual-ports)
 #:use-module (ebbot env)
 #:use-module (ice-9 ftw);;scandir
 #:export (get-rand-file-name
	   chunk-a-tweet
	   get-counter
	   set-counter
	   find-by-id
	   get-all-excerpts-alist
	   get-all-hashtags-string
	   get-nonce
	   get-image-file-name))

(define *working-dir* (@@ (ebbot env) *working-dir*))
(define *tweet-length* (@@ (ebbot env) *tweet-length*))
(define *bearer-token* (@@ (ebbot env) *bearer-token*))  ;;this does not change


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
	 (p  (open-input-file (string-append *working-dir* "/last-posted.json")))
	 (a (json-string->scm (get-string-all p)))
	 (dummy (close-port p))
	 (b (assoc-ref a "last-posted-id")))
    b))

(define (set-counter x)
(let* ((p  (open-output-file (string-append *working-dir* "/last-posted.json")))
	 (a (scm->json-string `(("last-posted-id" . ,x))))
	 (dummy (put-string p a)))
  (close-port p)))




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
  (let* ((p  (open-input-file (string-append *working-dir* "/db.json")))
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
  (let* ((p  (open-input-file (string-append *working-dir* "/hashtags.json")))
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
	((string=? directive "random")(string-append *working-dir* "/random/" (get-random-image (string-append *working-dir* "/random/"))) )	
	(else (string-append *working-dir* "/specific/" directive))
     ))
