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
	     (ice-9 common-list) ;;pick
	     )


(define working-dir "/home/mbc/projects/ebbot/data/acct1/")

(define (get-multiple-tweets s l lst)
  ;;s: the string
  ;;l: length of tweet (240 for twitter)
  ;;lst: initially '()
  (if (< (string-length s) l)
      (begin
	(set! lst (cons s lst))
	(reverse lst))
      (let* ((end (string-rindex s #\space 0 241))
	     (dummy (set! lst (cons (substring s 0 end) lst)))
	     (rest (substring s (+ end 1))))
	(get-multiple-tweets rest l lst))))

  
(define (get-all-excerpts)
  (let* ((p  (open-input-file "../data/acct1/test.json"))
	 (a (json-string->scm (get-string-all p))))	
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
  (let* ((p  (open-input-file (string-append working-dir "test.json")))
	 (a  (vector->list (json-string->scm (get-string-all p))))
	 (id 438)
	 (result (find-by-id a id))

	)
(pretty-print result)
  ))
