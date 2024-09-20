(define-module (babweb lib format) 
  #:use-module (web client)
  #:use-module (srfi srfi-19) ;; date time
  #:use-module (srfi srfi-1)  ;;list searching; delete-duplicates in list 
  #:use-module (srfi srfi-9)  ;;records
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
  #:use-module (ice-9 textual-ports)
  #:use-module (babweb lib html)
  #:export (main))

;;input: a text file with quotes that are delimitted by <CR><LF>
;;output: a json that is appropriate for consing to the json database. The quotes will be annotated with source, and image if available.

;; database fields: id, content, image

;;https://dthompson.us/posts/rendering-html-with-sxml-and-gnu-guile.html

(define working-dir "")
(define db "/db.json")                   ;;the database that provides quotes for tweets and is processed through
(define last-posted "/last-posted.json") ;;last posted id; next tweet is last-posted + 1

  
(define (get-all-new-quotes f)
  (let* ((p  (open-input-file f))
    	 (all-quotes   (string-split  (get-string-all p) #\newline)))    
    all-quotes))

(define (clean-chars s)
  ;;remove offensive characters
  (let* ((out (string-replace-substring s "'" "%27"))
	 (out (string-replace-substring out "’" "%27"))
	 (out (string-replace-substring out "\"" "%22"))
	 (out (string-replace-substring out "“" "%22"))
	 (out (string-replace-substring out "”" "%22"))
	 (out (string-replace-substring out "…" "..."))

	 )
    out))



(define (process-quotes old new counter )
  ;; old: original list
  ;; new: '()
  ;; counter: 0
  ;;suffix e.g. "--Edward Bernays, Propaganda (1928)"
  (if (null? (cdr old))
      (begin
	(if (> (string-length (car old)) 2)
	(set! new (cons `(,(cons "content"  (clean-chars (car old))) ("image" . ,(cadr old))  ("id" . ,counter)) new)))
	new)
      (begin
	(if (> (string-length (car old)) 2)
	    (begin	
	      (set! new (cons `(,(cons "content" (clean-chars (car old))) ("image" . ,(cadr old))("id" . ,counter)) new))
	      (set! counter (+ 1 counter))))
	(process-quotes (cddr old) new counter ))
      ))


;;this version appends to existing json
;; (define (save-quotes-as-json x)
;; (let* ((p  (open-output-file (string-append working-dir excerpts)))
;; 	 (a (scm->json-string x))
;; 	 (dummy (put-string p a)))
;;   (close-port p)))


(define (save-quotes-as-json x)
  ;;writes to db.json
(let* ((p  (open-output-file (string-append working-dir "/db.json")))
	 (a (scm->json-string x))
	 (dummy (put-string p a)))
  (close-port p)))


;;/gnu/store/pm4swxzzcz77li6xgsf9xl2rskk4228r-guile-next-3.0.9-0.3b76a30/bin/guile -L /home/mbc/projects/babweb -e '(babweb lib format)' -s /home/mbc/projects/babweb/babweb/lib/format.scm . destination.txt

(define (main args)
  ;; args: '( "working-dir" "new-excerpts-file-name"  )
  (let* ((start-time (current-time time-monotonic))
	 (dummy (set! working-dir (cadr args)))
	; (counter (get-counter))
	 (all-new-quotes (get-all-new-quotes (string-append working-dir "/" (caddr args))))
	 ;;used when appending
	 ;(last-id (get-last-id))
	;(start (if (= last-id 0) 0 (+ last-id 1)))  ;;record to start populating
        (start 0)
	(new-list (process-quotes all-new-quotes '() start ))
	(dummy (save-quotes-as-json (list->vector new-list)))
	 (stop-time (current-time time-monotonic))
	 (elapsed-time (ceiling (/ (time-second (time-difference stop-time start-time)) 60)))
	 )
   (pretty-print all-new-quotes)    
   ;; (pretty-print (string-append "Elapsed time: " (number->string  elapsed-time) " minutes." ))
   ;; #f
    ))
