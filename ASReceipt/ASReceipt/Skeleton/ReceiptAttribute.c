/*
 * Generated by asn1c-0.9.28 (http://lionet.info/asn1c)
 * From ASN.1 module "ReceiptModule"
 * 	found in "Payload"
 * 	`asn1c -fnative-types`
 */

#include "ReceiptAttribute.h"

static asn_TYPE_member_t asn_MBR_ReceiptAttribute_1[] = {
	{ ATF_NOFLAGS, 0, offsetof(struct ReceiptAttribute, type),
		(ASN_TAG_CLASS_UNIVERSAL | (2 << 2)),
		0,
		&asn_DEF_NativeInteger,
		0,	/* Defer constraints checking to the member type */
		0,	/* PER is not compiled, use -gen-PER */
		0,
		"type"
		},
	{ ATF_NOFLAGS, 0, offsetof(struct ReceiptAttribute, version),
		(ASN_TAG_CLASS_UNIVERSAL | (2 << 2)),
		0,
		&asn_DEF_NativeInteger,
		0,	/* Defer constraints checking to the member type */
		0,	/* PER is not compiled, use -gen-PER */
		0,
		"version"
		},
	{ ATF_NOFLAGS, 0, offsetof(struct ReceiptAttribute, value),
		(ASN_TAG_CLASS_UNIVERSAL | (4 << 2)),
		0,
		&asn_DEF_OCTET_STRING,
		0,	/* Defer constraints checking to the member type */
		0,	/* PER is not compiled, use -gen-PER */
		0,
		"value"
		},
};
static const ber_tlv_tag_t asn_DEF_ReceiptAttribute_tags_1[] = {
	(ASN_TAG_CLASS_UNIVERSAL | (16 << 2))
};
static const asn_TYPE_tag2member_t asn_MAP_ReceiptAttribute_tag2el_1[] = {
    { (ASN_TAG_CLASS_UNIVERSAL | (2 << 2)), 0, 0, 1 }, /* type */
    { (ASN_TAG_CLASS_UNIVERSAL | (2 << 2)), 1, -1, 0 }, /* version */
    { (ASN_TAG_CLASS_UNIVERSAL | (4 << 2)), 2, 0, 0 } /* value */
};
static asn_SEQUENCE_specifics_t asn_SPC_ReceiptAttribute_specs_1 = {
	sizeof(struct ReceiptAttribute),
	offsetof(struct ReceiptAttribute, _asn_ctx),
	asn_MAP_ReceiptAttribute_tag2el_1,
	3,	/* Count of tags in the map */
	0, 0, 0,	/* Optional elements (not needed) */
	-1,	/* Start extensions */
	-1	/* Stop extensions */
};
asn_TYPE_descriptor_t asn_DEF_ReceiptAttribute = {
	"ReceiptAttribute",
	"ReceiptAttribute",
	SEQUENCE_free,
	SEQUENCE_print,
	SEQUENCE_constraint,
	SEQUENCE_decode_ber,
	SEQUENCE_encode_der,
	SEQUENCE_decode_xer,
	SEQUENCE_encode_xer,
	0, 0,	/* No PER support, use "-gen-PER" to enable */
	0,	/* Use generic outmost tag fetcher */
	asn_DEF_ReceiptAttribute_tags_1,
	sizeof(asn_DEF_ReceiptAttribute_tags_1)
		/sizeof(asn_DEF_ReceiptAttribute_tags_1[0]), /* 1 */
	asn_DEF_ReceiptAttribute_tags_1,	/* Same as above */
	sizeof(asn_DEF_ReceiptAttribute_tags_1)
		/sizeof(asn_DEF_ReceiptAttribute_tags_1[0]), /* 1 */
	0,	/* No PER visible constraints */
	asn_MBR_ReceiptAttribute_1,
	3,	/* Elements count */
	&asn_SPC_ReceiptAttribute_specs_1	/* Additional specs */
};

