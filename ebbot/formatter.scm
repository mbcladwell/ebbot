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

;;input: a text file with quotes that are delimitted by <CR><LF>
;;output: a json that is appropriate for consing to the json database. The quotes will be annotated with source, and image if available.

;; database fields: id, content, image
;; meta fields: author, title, appendage;  appendage is what will be appended to the quote e.g. "--Edward Bernays (Propaganda, 1928)"

;;four files:
(define working-dir "")
(define db "/db.json")                   ;;the database that provides quotes for tweets and is processed through
(define meta "/meta.json")               ;; meta-data
(define last-posted "/last-posted.json") ;;last posted id; next tweet is last-posted + 1
(define excerpts "/excerpts.json")       ;;temp holder that is freshly formatted quotes; must be merged into db



(define (get-last-id)
  ;;start with (+ last-posted 1) for this session unless last-posted==0 then start with 0
  (let* (
	 (p  (open-input-file (string-append working-dir last-posted)))
	 (a (json-string->scm (get-string-all p)))
	 (dummy (close-port p))
	 (b (assoc-ref a "last-id")))
    b))

(define (set-last-id x)
(let* ((p  (open-output-file (string-append working-dir last-posted)))
	 (a (scm->json-string `(("last-id" . ,x))))
	 (dummy (put-string p a)))
  (close-port p)))

  
(define (get-all-new-quotes f)
  (let* ((p  (open-input-file f))
    	 (all-quotes   (string-split  (get-string-all p) #\newline)))    
    all-quotes))

;; (("content"
;;     .
;;     "Propaganda's goal is to transform the buyer???s very world, so that the product must appear to be desirable as if without the prod of salesmanship.")
;;    ("image" . "")
;;    ("id" . 6))


(define (process-quotes old new counter)
  ;; old: original list
  ;; new: '()
  ;; counter: 0
  (if (null? (cdr old))
      (begin
	(if (> (string-length (car old)) 1)
	(set! new (cons `(,(cons "content" (car old)) ("image" . "")  ("id" . ,counter)) new)))
	new)
      (begin
	(if (> (string-length (car old)) 1)
	    (begin
	      (set! new (cons `(,(cons "content" (car old)) ("image" . "")("id" . ,counter)) new))
	      (set! counter (+ 1 counter))))
	(process-quotes (cdr old) new counter))
      ))


(define (save-quotes-as-json x)
(let* ((p  (open-output-file (string-append working-dir excerpts)))
	 (a (scm->json-string x))
	 (dummy (put-string p a)))
  (close-port p)))



(define (main args)
  ;; args: '( "working-dir" "new-excerpts-file-name" )
  (let* ((start-time (current-time time-monotonic))
	 (dummy (set! working-dir (cadr args)))
	; (counter (get-counter))
	 (all-new-quotes (get-all-new-quotes "/home/mbc/projects/ebbot/data/acct1/propaganda-modv2.txt"))
	 (last-id (get-last-id))
	(start (if (= last-id 0) 0 (+ last-id 1)))  ;;record to start populating
	; (dummy (tweet-content all-excerpts new-counter))
					; (dummy (set-counter new-counter))


	(new-list (process-quotes all-new-quotes '() 0))
	(dummy (save-quotes-as-json (list->vector new-list)))
	 (stop-time (current-time time-monotonic))
	 (elapsed-time (ceiling (/ (time-second (time-difference stop-time start-time)) 60)))
	 )
   (pretty-print new-list)    
   ;; (pretty-print (string-append "Elapsed time: " (number->string  elapsed-time) " minutes." ))
   ;; #f
    ))
