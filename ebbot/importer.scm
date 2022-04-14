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



(define (get-occupied)
  ;;occupied is the last id where content is full
  ;;start with (+ occupied 1) for this session unless occupied==0 then start with 0
  (let* (
	 (p  (open-input-file "/home/mbc/projects/ebbot/data/occupied.json"))
	 (a (json-string->scm (get-string-all p)))
	 (dummy (close-port p))
	 (b (assoc-ref a "last-occupied-id")))
    b))

(define (set-occupied x)
(let* ((p  (open-output-file "/home/mbc/projects/ebbot/data/idcounter.json"))
	 (a (scm->json-string `(("last-occupied-id" . ,x))))
	 (dummy (put-string p a)))
  (close-port p)))

  
(define (get-all-new-quotes)
  (let* ((p  (open-input-file "/home/mbc/projects/ebbot/data/destination.txt"))
    	 (a   (string-split  (get-string-all p) #\newline)))
    
    a))



(define (main args)
  ;; args: '( "script name" "past days to query" "Number of articles to pull")
  (let* ((start-time (current-time time-monotonic))
	; (counter (get-counter))
	 (all-new-quotes (get-all-new-quotes))
	 (last-occupied (get-occupied))
	(start (if (= last-occupied 0) 0 (+ last-occupied 1)))  ;;record to start populating
	; (dummy (tweet-content all-excerpts new-counter))
	; (dummy (set-counter new-counter))
	 (stop-time (current-time time-monotonic))
	 (elapsed-time (ceiling (/ (time-second (time-difference stop-time start-time)) 60)))
	 )
   (pretty-print (cadr all-new-quotes))    
   ;; (pretty-print (string-append "Elapsed time: " (number->string  elapsed-time) " minutes." ))
   ;; #f
    ))
