(define-module (test)
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
#:use-module (rnrs io ports)
;#:use-module (ice-9 textual-ports)
	     )

;;guix shell --container --network --expose=/etc/ssl/certs=/etc/ssl/certs guile guile-json guile-readline guile-gnutls -- guile -L . ./test.scm
;;guix shell --container --pure -N -P -m manifest.scm -- guile ./test.scm

(define (convert-to-encrypted fin fout)
 (let* ((p  (open-input-file fin))
	(bytes64  (base64-encode (get-bytevector-all p)))
	(dummy (close-port p))
	(p2  (open-output-file fout))	
	)	
    (put-string p2 bytes64)))



(define (main)
  (let* ((start-time (current-time time-monotonic))	 
	 (_ (pretty-print (string-append "=====test suite begin: " (number->string (time-second start-time)) " ===========")))
;;       ===================================================================================


	 (_ (convert-to-encrypted "/home/mbc/projects/ebbot/env-in-clear.json" "/home/mbc/projects/ebbot/env.txt"))

	  
;;       ===================================================================================	 
	 (stop-time (current-time time-monotonic))
	 (_ (pretty-print (string-append "=====test suite end: " (number->string (time-second stop-time)) " ===========")))
	 (elapsed-time (time-second (time-difference stop-time start-time))))
    (begin
;;      (display  a)
      
      (pretty-print (string-append "Shutting down after " (number->string elapsed-time) " seconds of use."))
    )))
   

(main)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
