#!/gnu/store/1jgcbdzx2ss6xv59w55g3kr3x4935dfb-guile-3.0.8/bin/guile \
-e main -s
!#
;;this executable expects preformated json as input for addition to db
;;only function is consing elements to json
;;meant to be run as a cron job pinging a directory
;;directory contain one or more files - each file containing one or more elements in json format

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
	     (ice-9 ftw) ;;file-tree-walk; scandir
	     (ice-9 textual-ports)
	     )


(define working-dir "/home/mbc/projects/ebbot/data/acct1/")


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


(define (import-file f)
  ;;file must be json format
  (let* ((p  (open-input-file (string-append working-dir "dbmod.json")))
	 (a  (vector->list (json-string->scm (get-string-all p))))
	 (dummy (close-port p))
	 (p2  (open-input-file (string-append working-dir "imports/" f)))
	 (b  (vector->list (json-string->scm (get-string-all p2))))	 
	 (dummy (close-port p2))
	 (last-id (assoc-ref (car a) "id"))
 	 (start (+ last-id 1))  ;;record to start populating	
	 (new-db (list->vector (add-two-lists b a start)))
	 (p3  (open-output-file (string-append working-dir "dbmod.json")))
	 (c (scm->json-string new-db))
	 (dummy (put-string p3 c)))
     (close-port p3)
    ))

(define (main args)
  (let* ((start-time (current-time time-monotonic))
	 (a (scandir (string-append working-dir "imports")))
	 (dummy (if (> (length a) 2)
		    (let* ((b (cddr a))) ;;get rid of . and ..
		      (map import-file  b))))
	 (stop-time (current-time time-monotonic))
	 (elapsed-time (ceiling (/ (time-second (time-difference stop-time start-time)) 60))))	    
  ;; (pretty-print a   )    
   ;; (pretty-print (string-append "Elapsed time: " (number->string  elapsed-time) " minutes." ))
    #f
    ))
