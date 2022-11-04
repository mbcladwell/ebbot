(define-module (ebbot env) 
#:use-module (srfi srfi-19) ;; date time
#:use-module (srfi srfi-1)  ;;list searching; delete-duplicates in list 
#:use-module (ice-9 rdelim)
#:use-module (ice-9 popen)
#:use-module (ice-9 regex) ;;list-matches
#:use-module (ice-9 pretty-print)
#:use-module (ice-9 binary-ports)
#:use-module (json)
#:use-module (rnrs bytevectors)
#:use-module (rnrs io ports)
#:use-module (gcrypt base64)
#:export ( 
	  *oauth-consumer-key*
	  *oauth-consumer-secret*
	  *bearer-token*
	  *oauth-access-token*
	  *oauth-token-secret*
	  *client-id*
	  *client-secret*
	  ))


  (let*  ((p  (open-input-file  "./env.txt"))
 	  (a (get-string-all p))
	  (b (base64-decode a))
	  (varlst (json-string->scm (utf8->string b)))
	  )
    (begin
      (set! *oauth-consumer-key* (assoc-ref varlst "oauth-consumer-key"))
      (set! *oauth-consumer-secret* (assoc-ref varlst "oauth-consumer-secret"))
      (set! *bearer-token* (assoc-ref varlst "bearer-token"))
      (set! *oauth-access-token* (assoc-ref varlst "oauth-access-token"))
      (set! *oauth-token-secret* (assoc-ref varlst "oauth-token-secret"))
      (set! *client-id* (assoc-ref varlst "client-id"))
      (set! *client-secret* (assoc-ref varlst "client-secret"))))
  



(define (convert-to-encrypted fin fout)
 (let* ((p  (open-input-file fin))
	(bytes64  (base64-encode (get-bytevector-all p)))
	(dummy (close-port p))
	(p2  (open-output-file fout))	
	)	
    (put-string p2 bytes64)))

