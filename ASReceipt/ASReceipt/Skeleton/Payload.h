/*
 * Generated by asn1c-0.9.24 (http://lionet.info/asn1c)
 * From ASN.1 module "ReceiptModule"
 * 	found in "../payload"
 */

#ifndef	_Payload_H_
#define	_Payload_H_


#include <asn_application.h>

/* Including external dependencies */
#include <asn_SET_OF.h>
#include <constr_SET_OF.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Forward declarations */
struct ReceiptAttribute;

/* Payload */
typedef struct Payload {
	A_SET_OF(struct ReceiptAttribute) list;
	
	/* Context for parsing across buffer boundaries */
	asn_struct_ctx_t _asn_ctx;
} Payload_t;

/* Implementation */
extern asn_TYPE_descriptor_t asn_DEF_Payload;

#ifdef __cplusplus
}
#endif

/* Referred external types */
#include "ReceiptAttribute.h"

#endif	/* _Payload_H_ */
#include <asn_internal.h>
