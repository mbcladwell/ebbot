#!/gnu/store/1jgcbdzx2ss6xv59w55g3kr3x4935dfb-guile-3.0.8/bin/guile \
-e main -s
!#

(use-modules (web client)
	     (srfi srfi-19) ;; date time
	     (srfi srfi-1)  ;;list searching; delete-duplicates in list 
	     (srfi srfi-9)  ;;records
	     (artanis utils) ;;string->sha-256
	     (web response)
	     (web request)
	     (web uri)
	     (dbi dbi)  
	     (ice-9 rdelim)
	     (ice-9 i18n)   ;; internationalization
	     (ice-9 popen)
	     (ice-9 regex) ;;list-matches
	     (ice-9 receive)	     
	     (ice-9 string-fun)  ;;string-replace-substring
	     (ice-9 pretty-print)
	     (json)
	     (ice-9 textual-ports)
	     (gcrypt base64)
	     (rnrs bytevectors)
	     (ice-9 binary-ports) ;;get-bytevector-all
	     )

;;(load "/home/mbc/projects/ebbot/ebbot/import.scm")
(define working-dir "")  ;;/home/mbc/projects/ebbot/data

(define (get-tokens handle)
  ;;must be the @handle
  (let* (
  	 (tbot (dbi-open "mysql" "plapan_tbot_admn:welcome:plapan_tbot:tcp:192.254.187.215:3306"))
;;	 (sql-statement (string-append "SELECT auth_token, auth_token_secret, email FROM customer WHERE handle = '@jblo'"))
	 (sql-statement (string-append "SELECT * FROM customer"))
	 (dummy (dbi-query tbot sql-statement))
	 (ret (dbi-get_row tbot))
	  (results '())
	  (dummy (while (not (equal? ret #f))
	  	  (set! results (cons ret results))
	  	  (set! ret (dbi-get_row tbot))
	  	  ))
	  (dummy (dbi-close tbot ))
	 )
    (pretty-print (dbi-get_row tbot))

  ))

;; (define (update-accounts-file handle token)
;;   ;;this is not used
;;   (let* (
;; 	  (item `(("handle" . ,handle)("token" . ,token)))
;; 	 (p  (open-input-file (string-append working-dir "/accounts.json")))
;; 	 (a  (vector->list (json-string->scm (get-string-all p))))
;; 	 ;(a  (vector->list (json-string->scm "[{\"id\":1,\"custid\":\"\",\"handle\":\"dummy1\",\"email\":\"email\"},{\"id\":0,\"custid\":\"\",\"handle\":\"dummy0\",\"email\":\"email0\"}]")))	 
;; 	 (dummy (close-port p))
;; 	 (length-orig (length a))
;; 	 (b  (add-two-lists (list item) a length-orig))
;; 	 (c (scm->json-string (list->vector b)))
;; 	 (p  (open-output-file (string-append working-dir "/accounts.json")))
;; 	 (dummy (put-string p c))
;; 	 (dummy (close-port p))	 
;; 	 )
;;     #f))

(define (save-quotes-as-json x)
(let* ((p  (open-output-file "/home/mbc/projects/ebbot/data/acct1/excerpt-db.json"))
	 (a (scm->json-string x))
	 (dummy (put-string p a)))
  (close-port p)))


(define (make-last-posted-json d)
  ;;d: the project directory 
  (let* ((p  (open-output-file (string-append d "/last-posted.json")))
	 (a (scm->json-string '(("last-posted-id" . 0))))
	 (dummy (put-string p a)))
    (close-port p)))

(define (init-db d)
  (let* ((p  (open-output-file (string-append d "/db.json")))
	 (a (scm->json-string '(("content" . "first test tweet")("image" . "")("id" . 0))))
	 (dummy (put-string p a)))
    (close-port p)))

(define (convert-to-encrypted fin fout)
  ;;read in a json
  ;;write out the base64 encoded text as "env.txt"
 (let* ((p  (open-input-file fin))
	(bytes64  (base64-encode (get-bytevector-all p)))
	(dummy (close-port p))
	(p2  (open-output-file fout))	
	)	
    (put-string p2 bytes64)))


;; ./run-init-acct.sh /home/mbc/projects/bab/data handle /home/mbc/projects/bab/bab/creds.json 

(define (main args)
  ;; args: '( "working-dir" handle json_file )
  ;;working dir is /home/mbc/projects/bab/data, the data directory
  ;;handle is @handle without the @; used to create customer directory
  ;;see below for json template creds.json
  (let* (
	 (dummy (set! working-dir (cadr args)))
	 (handle (caddr args))
	 (creds-input-json (cadddr args))
	 (athandle (string-append "@" handle))
	 (cust-dir (string-append working-dir "/" handle (substring (string->sha-256 handle ) 0 6)))
	 (creds-file (string-append cust-dir "/env.txt" ))
	 (dummy (mkdir cust-dir))
	 (dummy (make-last-posted-json cust-dir))
	 (dummy (init-db cust-dir))
	 (dummy (convert-to-encrypted creds-input-json  creds-file))
	 (dummy (mkdir (string-append cust-dir "/specific")))
	 (dummy (mkdir (string-append cust-dir "/random")))
	 )
   (pretty-print args)    
    ))

;;accounts.json:
;;[{"id":1,"custid":"","handle":"dummy1","email":"email1"},{"id":0,"custid":"","handle":"dummy0","email":"email0"}]

;; creds.json
;; {"oauth-consumer-key":"tCO2sjfisuidunndk7qodx",
;; "oauth-consumer-secret":"CMjjY1EogNfZwYoVcsflajsdljfiiUz1gsAemMg1jJZi",
;; "bearer-token":"",
;; "oauth-access-token":"151643193as;ldf;sldeMQKGsRA6sx1PBq",
;; "oauth-token-secret":"BqbfTJU3slskdodolskskskslsol1SwwLtA5AVI",
;; "client-id":"WFosllskdolskkdododoosU6MTpjaQ",
;; "client-secret":""}
