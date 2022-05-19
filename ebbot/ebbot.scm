;#!/gnu/store/1jgcbdzx2ss6xv59w55g3kr3x4935dfb-guile-3.0.8/bin/guile \
;-e main -s
;!#
(define-module (ebbot ebbot) 
#:use-module (web client)
#:use-module (srfi srfi-19) ;; date time
#:use-module (srfi srfi-1)  ;;list searching; delete-duplicates in list 					;  #:use-module (srfi srfi-9)  ;;records
#:use-module (web response)
#:use-module (web request)
; #:use-module (hashing fixnums)
#:use-module (web uri)
#:use-module (ice-9 rdelim)
#:use-module (ice-9 i18n)   ;; internationalization
#:use-module (ice-9 popen)
#:use-module (ice-9 regex) ;;list-matches
#:use-module (ice-9 receive)	     
#:use-module (ice-9 string-fun)  ;;string-replace-substring
#:use-module (ice-9 pretty-print)
#:use-module (json)
#:use-module (ice-9 textual-ports)
#:use-module (ebbot twitter)	    
#:export (init)
)

;;(add-to-load-path "/gnu/store/lxbvzmdcv82ik37z4np3c45p11iic7qx-guile-json-4.5.2/share/guile/site/3.0")
;;(add-to-load-path "/home/mbc/projects/ebbot")


(define working-dir "")
(define tweet-length 0)


(define (get-counter)
  ;;counter is the last tweeted id
  ;;start with (+ counter 1) for this session
  (let* (
	 (p  (open-input-file (string-append working-dir "/last-posted.json")))
	 (a (json-string->scm (get-string-all p)))
	 (dummy (close-port p))
	 (b (assoc-ref a "last-posted-id")))
    b))

(define (set-counter x)
(let* ((p  (open-output-file (string-append working-dir "/last-posted.json")))
	 (a (scm->json-string `(("last-posted-id" . ,x))))
	 (dummy (put-string p a)))
  (close-port p)))

  
(define (get-all-excerpts-alist)
  (let* ((p  (open-input-file (string-append working-dir "/db.json")))
	 (a (vector->list (json-string->scm (get-string-all p)))))	
     a))


(define (find-by-id lst id)
  ;;find an entity by id
  ;;return whole entity
  (if (null? (cdr lst))
      (if (= (assoc-ref (car lst) "id") id) (car lst) #f)
      (if (= (assoc-ref (car lst) "id") id)
	   (car lst)
	  (find-by-id (cdr lst) id))))



(define (init args)
  ;; args: '( "working-dir" tweet-length )
  (let* ((start-time (current-time time-monotonic))
	 (dummy (set! working-dir (cadr args)))
	 (dummy (set! tweet-length (string->number (caddr args))))
	 
	 (counter (get-counter))
	 (all-excerpts (get-all-excerpts-alist))
	 (max-id (assoc-ref (car all-excerpts) "id"))
	 (new-counter (if (= counter max-id) 0 (+ counter 1)))
	 (entity (find-by-id all-excerpts new-counter))	 
	 (tweets (chunk-a-tweet (assoc-ref entity "content") 280))	 
	 (dummy (set-counter new-counter))
	 (stop-time (current-time time-monotonic))
	 (elapsed-time (ceiling (/ (time-second (time-difference stop-time start-time)) 60)))
	 )
   (oauth1-post-tweet-recurse tweets)    
   ;; (pretty-print (string-append "Elapsed time: " (number->string  elapsed-time) " minutes." ))
   ;; #f
    ))
