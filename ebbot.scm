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

;;(define counter 0)
;;(define max-excerpts 0)

(define-record-type <idcounter>
  (make-idcounter last-posted-id )
  idcounter?
  (last-posted-id idcounter-last-posted-id set-idcounter-last-posted-id!)
  )


(define-record-type <excerpt>
  (make-excerpt id title author field4 field5 content)
  excerpt?
  (id    excerpt-id set-excerpt-id!)
  (title excerpt-title set-excerpt-title!)
  (author excerpt-author set-excerpt-author!)
  (field4 excerpt-field4)
  (field5 excerpt-field5)
  (content excerpt-content set-excerpt-content!)
  )



(define (get-counter)
  ;;counter is the last tweeted id
  ;;start with (+ counter 1) for this session
  (let* (
	 (p  (open-input-file "/home/mbc/projects/ebbot/ebbot/idcounter.json"))
	 (a (json-string->scm (get-string-all p)))
	 (dummy (close-port p))
	 (b (assoc-ref a "last-posted-id")))
    b))

(define (set-counter x)
(let* ((p  (open-output-file "/home/mbc/projects/ebbot/ebbot/idcounter.json"))
	 (a (scm->json-string `(("last-posted-id" . ,x))))
	 (dummy (put-string p a)))
  (close-port p)))

  
(define (get-all-excerpts)
  (let* ((p  (open-input-file "/home/mbc/projects/ebbot/ebbot/excerpts.json"))
	 (a (json-string->scm (get-string-all p))))	
    a))

(define (tweet-content a n)
  ;;a: all excerpts
  ;;n: index of excerpt to tweet
  (pretty-print (assoc-ref (vector-ref a n) "content"))
  )


(define (main args)
  ;; args: '( "script name" "past days to query" "Number of articles to pull")
  (let* ((start-time (current-time time-monotonic))
	 (counter (get-counter))
	 (all-excerpts (get-all-excerpts))
	 (max-excerpts (- (vector-length all-excerpts) 1))
	 (new-counter (if (= counter max-excerpts) 0 (+ counter 1)))
	 (dummy (tweet-content all-excerpts new-counter))
	 (dummy (set-counter new-counter))
	 (stop-time (current-time time-monotonic))
	 (elapsed-time (ceiling (/ (time-second (time-difference stop-time start-time)) 60)))
	 )
   ;;(pretty-print new-counter)    
   ;; (pretty-print (string-append "Elapsed time: " (number->string  elapsed-time) " minutes." ))
    #f
    ))
