#!/gnu/store/1jgcbdzx2ss6xv59w55g3kr3x4935dfb-guile-3.0.8/bin/guile \
-e main -s
!#

(add-to-load-path "/gnu/store/lxbvzmdcv82ik37z4np3c45p11iic7qx-guile-json-4.5.2/share/guile/site/3.0")
(use-modules (web client)
	     (srfi srfi-19) ;; date time
	     (srfi srfi-1)  ;;list searching; delete-duplicates in list 
	     (srfi srfi-9)  ;;records
	     (web response)
	     (web request)
	  ;   (hashing fixnums)
	     (web uri)
	     (ice-9 rdelim)
	     (ice-9 i18n)   ;; internationalization
	     (ice-9 popen)
	     (ice-9 regex) ;;list-matches
	     (ice-9 receive)	     
	     (ice-9 string-fun)  ;;string-replace-substring
	     (ice-9 pretty-print)
	     (json)
	     (ice-9 textual-ports)
	     )

(load "/home/mbc/projects/bab/bab/twitter.scm")
(define working-dir "")
(define tweet-length 0)

;; (define-record-type <idcounter>
;;   (make-idcounter last-posted-id )
;;   idcounter?
;;   (last-posted-id idcounter-last-posted-id set-idcounter-last-posted-id!)
;;   )


;; (define-record-type <excerpt>
;;   (make-excerpt id image content)
;;   excerpt?
;;   (id    excerpt-id set-excerpt-id!)
;;   (image excerpt-image)
;;   (content excerpt-content set-excerpt-content!)
;;   )


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


;; (define (get-multiple-tweets s l lst)
;;   ;;s: the string
;;   ;;l: length of tweet (240 for twitter)
;;   ;;lst: initially '()
;;   (if (< (string-length s) l)
;;       (begin
;; 	(set! lst (cons s lst))
;; 	(reverse lst))
;;       (let* ((end (string-rindex s #\space 0 241))
;; 	     (dummy (set! lst (cons (substring s 0 end) lst)))
;; 	     (rest (substring s (+ end 1))))
;; 	(get-multiple-tweets rest l lst))))


;; (define (get-tweets a)
;;   ;;a: an entity
;;   (let* ((excerpt (assoc-ref a "content"))
;; 	 (nchar (string-length excerpt))
;; 	 (ntweets (ceiling (/ nchar 240)))
;; 	 (tweets (if (> ntweets 1) (get-multiple-tweets excerpt tweet-length '()) `(,excerpt))))
;;    tweets
;;   ))


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
   (pretty-print tweets)    
   ;; (pretty-print (string-append "Elapsed time: " (number->string  elapsed-time) " minutes." ))
   ;; #f
    ))
