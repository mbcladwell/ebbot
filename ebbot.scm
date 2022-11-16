(define-module (ebbot) 
#:use-module (web client)
#:use-module (srfi srfi-19) ;; date time
#:use-module (srfi srfi-1)  ;;list searching; delete-duplicates in list    
#:use-module (web response)
#:use-module (web request)
#:use-module (web uri)
#:use-module (ice-9 rdelim)
#:use-module (ice-9 i18n)   ;; internationalization
#:use-module (ice-9 popen)
#:use-module (ice-9 regex) ;;list-matches
#:use-module (ice-9 receive)	     
#:use-module (ice-9 string-fun)  ;;string-replace-substring
#:use-module (ice-9 pretty-print)
#:use-module (json)
#:use-module ((rnrs io ports) #:select ((get-string-all . get-string-all-rnrs)))
;;#:use-module ((ice-9 textual-ports) #:select ((get-string-all . get-string-all-txt)))
#:use-module (ice-9 textual-ports)
#:use-module (ebbot twitter)	 
#:use-module (ebbot image)
 #:use-module (rnrs bytevectors)
 #:use-module (gcrypt base64)
#:export (main
	  *working-dir*
))


(define *working-dir* "")
(define tweet-length 0)


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


;;to run
;;/gnu/store/1jgcbdzx2ss6xv59w55g3kr3x4935dfb-guile-3.0.8/bin/guile -L . -e '(ebbot)' -s ebbot.scm /home/mbc/data/jblo2cf0a6 260

(define (main args)
  ;; args: '( "working-dir" tweet-length )
  (let* ((start-time (current-time time-monotonic))
	 ;;(dummy (pretty-print (cadr args)))
	 (dummy (set! *working-dir* (cadr args)))
	 (dummy (set! tweet-length (string->number (caddr args))))
	 (counter (get-counter))
	 (all-excerpts (get-all-excerpts-alist))
	 (max-id (assoc-ref (car all-excerpts) "id"))
	 (new-counter (if (= counter max-id) 0 (+ counter 1)))
	 (entity (find-by-id all-excerpts new-counter))	 
	 (tweets (chunk-a-tweet (assoc-ref entity "content") 260))
	 (media-directive (assoc-ref entity "image"))
	 (image-file (get-image media-directive *working-dir*))
	 (media-id (if image-file (assoc-ref (upload-image image-file 2000) "media-id") ""))
	 (dummy (set-counter new-counter))
	 (stop-time (current-time time-monotonic))
	 (elapsed-time (ceiling (/ (time-second (time-difference stop-time start-time)) 60)))
	 )
    (begin
      (oauth1-post-tweet-recurse tweets "" media-id 0)
      (pretty-print "*oauth-access-token*: " *oauth-access-token*)
      (pretty-print "*oauth-token-secret*: " *oauth-token-secret*)
      )
;;    #f
    ))

