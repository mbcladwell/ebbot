(define-module (ebbot) 
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
#:use-module (ebbot env)
#:use-module (ebbot twitter)	 
#:use-module (ebbot image)
#:use-module (gcrypt base64)
#:use-module (rnrs bytevectors)
#:export (main
	  *working-dir*
	  ;;  *oauth-consumer-key*
	  ;; *oauth-consumer-secret*
	  ;; *bearer-token*
	  ;; *oauth-access-token*
	  ;; *oauth-token-secret*
	  ;; *client-id*
	  ;; *client-secret*
))


(define *working-dir* "")
(define tweet-length 0)
;; (define *oauth-consumer-key* #f)
;; (define *oauth-consumer-secret* #f)
;; (define *bearer-token* #f)
;; (define *oauth-access-token* #f)
;; (define *oauth-token-secret* #f)
;; (define *client-id* #f)
;; (define *client-secret* #f)


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

  
(define (get-all-excerpts-alist)
  (let* ((p  (open-input-file (string-append *working-dir* "/db.json")))
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


(define (main args)
  ;; args: '( "working-dir" tweet-length )
  (let* ((start-time (current-time time-monotonic))
	 ;;(dummy (pretty-print (cadr args)))
	 (dummy (set! *working-dir* (cadr args)))
	 (dummy (set! tweet-length (string->number (caddr args))))
	 ;;(dummy (get-vars *working-dir*))
	 ;; (p  (open-input-file (string-append *working-dir* "/env.txt")))
 	 ;; (a (get-string-all p))
	 ;; (b (base64-decode a))
	 ;; (varlst (json-string->scm (utf8->string b)))
	 ;; (dummy   (begin
	 ;; 	    (set! *oauth-consumer-key* (assoc-ref varlst "oauth-consumer-key"))
	 ;; 	    (set! *oauth-consumer-secret* (assoc-ref varlst "oauth-consumer-secret"))
	 ;; 	    (set! *bearer-token* (assoc-ref varlst "bearer-token"))
	 ;; 	    (set! *oauth-access-token* (assoc-ref varlst "oauth-access-token"))
	 ;; 	    (set! *oauth-token-secret* (assoc-ref varlst "oauth-token-secret"))
	 ;; 	    (set! *client-id* (assoc-ref varlst "client-id"))
	 ;; 	    (set! *client-secret* (assoc-ref varlst "client-secret"))))
	 (counter (get-counter))
	 (all-excerpts (get-all-excerpts-alist))
	 (max-id (assoc-ref (car all-excerpts) "id"))
	 (new-counter (if (= counter max-id) 0 (+ counter 1)))
	 (entity (find-by-id all-excerpts new-counter))	 
	 (tweets (chunk-a-tweet (assoc-ref entity "content") 260))
	 (media-directive (assoc-ref entity "image"))
	 (image-file (get-image media-directive *working-dir*))
	;; (media-id (if image-file (assoc-ref (upload-image (string-append working-dir "/images/" image-file) 2000) "media-id") ""))
	  (media-id (if image-file (assoc-ref (upload-image image-file 2000) "media-id") ""))
	 (dummy (set-counter new-counter))
	 (stop-time (current-time time-monotonic))
	 (elapsed-time (ceiling (/ (time-second (time-difference stop-time start-time)) 60)))
	 )
   (oauth1-post-tweet-recurse tweets "" media-id 0)    
    ;; (pretty-print (string-append "Elapsed time: " (number->string  elapsed-time) " minutes." ))
    ;;   (pretty-print (string-append "new-counter: " (number->string new-counter) " media-directive: "  media-directive  " image-file: " (if image-file (string-append working-dir "/images/" image-file) "f")))
 ;;   (pretty-print tweets)
 ;;   #f)
    ))

